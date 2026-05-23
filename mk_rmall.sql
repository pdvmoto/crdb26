
-- for CRDB only, too risky to use elsewhere..

set verify   off
set echo     off
set heading  off
set feedb    off
set linesize 192
set doc      off

set trimspool on

-- first
-- data, temp, redo, control
-- then some parameters.
-- but refrain from too many parameters and options,
-- as others may share the destination-directory
--

select 'rm ' || name from v$datafile ;

select 'rm ' || name from v$tempfile ;

select 'rm ' || member from v$logfile ;

select 'rm ' || name from v$controlfile ;

-- files at destinations pointed by parameters, Risky!

select 'rm ' || p.value || '/' || '*' || to_char ( sys_context ( 'USERENV', 'INSTANCE_NAME' ) ) || '*.*'
from v$parameter p
where p.value is not null
  and length ( trim ( p.value ) ) != 0
  and p.value != '/'
  and (   p.name like 'audit_file_dest%'
      or  p.name like 'background_dump_dest%'
      or  p.name like 'core_dump_dest%'
      or  p.name like 'dg_broker_config_fille%'
      or  p.name like 'spfile'
      or  p.name like 'user_dump_dest%'
      )
order by p.name ;

-- finally: the relevant stuff in OH  the files in $OH/dbs
-- use host cmds to generat

select '#' from dual ;

select 'rm ' || sys_context ('userenv','ORACLE_HOME') || '/dbs/init'   || to_char ( sys_context ( 'USERENV', 'INSTANCE_NAME' ) ) || '.ora' from dual 
select 'rm ' || sys_context ('userenv','ORACLE_HOME') || '/dbs/spfile' || to_char ( sys_context ( 'USERENV', 'INSTANCE_NAME' ) ) || '.ora' from dual 
select 'rm ' || sys_context ('userenv','ORACLE_HOME') || '/dbs/orapw'  || to_char ( sys_context ( 'USERENV', 'INSTANCE_NAME' ) )           from dual 

