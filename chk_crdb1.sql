rem
rem checks after first crdb
rem 

column con_id     format 9999
column mb_size    format 999999
column ts_name    format A20

column ctl_file   format A90
column log_file   format A90
column df_name    format A90
column tmp_file   format A90

column grp        format 999

column db_name    format A15
column pdb_name   format A15
column owner_name format A20

column dbid       format 999999999999
column guid       format A33
column omode      format A11
column restricted format A10

set linesize 150

select con_id, dbid, name, log_mode, open_mode from v$database ;

select con_id, name pdb_name, open_mode omode, restricted, dbid , guid
from v$pdbs ;

select ts.con_id, ts.name ts_name, ts.bigfile  
from v$tablespace ts
order by ts.con_id , ts.ts# ;

prompt .
prompt So far, the conainer (CDB) and the PDBs and tablespaces.
prompt 
prompt Next: the files... 
prompt . 

host read -t15 -p "check the info above, next: the files.." abc

select con_id, name ctl_file from v$controlfile  ; 

select l.con_id
, l.group#        grp
,	l.bytes/(1024*1024)	     mb_size
, lf.member			  log_file
from v$logfile lf, v$log l
where l.con_id = lf.con_id
  and l.group# = lf.group#
order by l.group# ; 

select df.con_id, bytes / ( 1024*1024) as mb_size,  df.name df_name
from v$datafile df
order by df.con_id;

set feedb on

select df.con_id, bytes / ( 1024*1024) as mb_size,  df.name df_name
from v$tempfile df
order by df.con_id;

prompt .
prompt ...and the bonus-query: check now much is already there.. 
prompt .

set echo on

select o.owner# owner, u.name owner_name
--, o.type#
, count (*) cnt 
from sys.obj$ o
   , sys.user$ u
   where user# = owner#
group by o.owner# , u.name --, o.type# 
order by o.owner# --, o.type#
; 

