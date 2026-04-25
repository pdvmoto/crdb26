
-- chks1.sql : first check.

-- cdb + pdbs: sizes + files


doc
        copied from checks..
	(and probable some leftover columns and queries)
#


set heading on
set feedback off
set lines 128
set pagesize 30

column  tablespace_name format a30
column  mfree           format 999,999,999
column  mused           format 999,999,999
column  total           format A30
column  mtotal          format 999,999,999
column  mb_total        format 999,999,999
column  mb_file         format 999,999,999
column  perc_free       format 999.99

column con              format 999
column tsnr             format 999
column fname            format A50
column f_name            format A50
column tsname           format A20 trunc
column pdb_name         format A12
column open_mode        format A12
column inst 		format 9999 head inst


break on pdb_name on con_id

prompt .
prompt .

prompt .
prompt name the PDBs and tablespaces.
prompt Beware: this excludes the CDB
prompt .

select df.con_id con_id
, p.name     as pdb_name
, ts.ts#     as tsnr
, ts.name    as tsname
,  round ( sum ( bytes /( 1024 * 1024) ) ) mb_total
--, df.*
from v$datafile   df
   , v$tablespace ts
   , v$containers p
where ts.con_id    = df.con_id
  and p.con_id     = ts.con_id
  and ts.ts# = df.ts#
group by df.con_id, p.name, ts.ts#, ts.name
order by df.con_id, ts.ts#
/

-- just containers and files, us V$ instead of GV$

with all_con_ids as 
  (  select con_id, name, open_mode from v$database 
  union all
     select con_id, name, open_mode from v$containers
  )
select c.con_id, c.name pdb_name, c.open_mode
, sum ( df.bytes ) / ( 1024 * 1024 ) 		as mb_total
from all_con_ids  c
   , v$datafile  df
where c.con_id = df.con_id
group by c.con_id, c.name, c.open_mode
order by c.con_id
;

select
'Total : ' as total,  round ( sum ( bytes /( 1024 * 1024) ) ) mtotal
from v$datafile df;

-- individual files, try adding NEXT

with all_con_ids as 
  (  select con_id, name, open_mode from v$database 
  union all
     select con_id, name, open_mode from v$containers
  )
select c.con_id, c.name pdb_name
,  df.bytes / ( 1024 * 1024 ) 			as mb_file
,  substr ( df.name , -40 ) 			f_name
from all_con_ids  c
   , v$datafile  df
where c.con_id = df.con_id
order by c.con_id
;


prompt .
prompt . check , compare to old leftovers..
prompt .
host read -t15 -p "check... " abc



-- now the demo with session and process..

column usrnm		format  A12 trunc
column osusr		format  A12	trunc
column machine		format  A20	trunc
column program		format  A12	trunc
column process		format  A10
column logon_time 	format A20
column spid		format 99999
column inst             format 999
column serial           format 9999
column sid              format 999
column sidser           format A70
column status           format A15


column con_id    format 9999
column pdb_name  format A10
column total     format A20


prompt .
prompt .
prompt where do connections and processes go, per instance and per PDB...
prompt .


-- select con_id, inst_id, count (*) from gv$session group by con_id, inst_id ;

-- select con_id, inst_id, count (*) from gv$process group by con_id, inst_id ;

-- now combine
with all_cont as (
	select con_id, inst_id, name, open_mode from gv$database
   union all
	select con_id, inst_id, name, open_mode from gv$containers
  )
, sum_procs as ( 
	select con_id, inst_id, count (*) cnt_procs 
	from gv$process 
	group by con_id, inst_id 
  )
, sum_sess as (
	select con_id, inst_id, count (*) cnt_sess 
	from gv$session 
	group by con_id, inst_id 
)
select c.con_id, c.name pdb_name, p.inst_id, cnt_procs, cnt_sess 
from all_cont  c
   left outer join  sum_procs p on p.con_id   = c.con_id and p.inst_id  = c.inst_id
   left outer join  sum_sess  s on s.con_id   = c.con_id and s.inst_id  = c.inst_id
order by c.con_id nulls first
;

prompt .
prompt .
host read -t15 -p "check connections and processes " abc


-- sga and resize events.

show sga

doc

        show sga size and memory resize ops (did it vary a lot?)

        note: values may differ from set-parameter (??)
        this is acutal claimed amount.

#

column name              format A35 trunc
column value             format A16 wrap
column nr_mem_resize_ops format 9,999
column datetime          format A20
column file_resize_ops   format 999,999 

select nvl ( pool, name )                        as name
     , to_char ( sum(bytes),  '999,999,999,999' ) as value
from v$sgastat
where 1=1 -- pool is not null
group by nvl ( pool, name )
order by name
/

select 'Total SGA'                               as name
     , to_char ( sum(bytes),  '999,999,999,999' ) as value
from v$sgastat
where 1=1 -- pool is not null
group by 'Total SGA'
/

-- recent sga_resizes

select inst_id, count (*) nr_mem_resize_ops from gv$memory_resize_ops
group by inst_id
order by inst_id ;

-- how many resize ops in last day

select to_char ( originating_timestamp, 'DD - HH24:MI' ) datetime, count (*) file_resize_ops
from V$DIAG_ALERT_EXT
where message_text like 'Resize%'
and originating_timestamp > ( sysdate - 24 )
group by to_char ( originating_timestamp, 'DD - HH24:MI' )
order by 1 desc ;

-- resize of files form v$alert ? 

