rem
rem checks after first crdb
rem 

column con_id     format 9999
column mb         format 999999
column fname      format A100

column db_name    format A15
column pdb_name   format A15

column dbid       format 999999999999
column guid       format A33
column omode      format A11
column restricted format A10

set linesize 150

select con_id, dbid, name, log_mode, open_mode from v$database ;

select con_id, name pdb_name, open_mode omode, restricted, dbid , guid
from v$pdbs ;

select con_id, bytes / ( 1024*1024) as mb,  name fname
from v$datafile
order by con_id;

select t.con_id, t.name, t.bigfile  
from v$tablespace t
order by con_id , ts# ;

