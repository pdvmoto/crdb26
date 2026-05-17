
-- for CRDB only, too risky to use elsewhere..

set heading off
set feedb off

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

select 'rm ' || p.value || '/*.*'
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

host echo rm $ORACLE_HOME/dbs/init$ORACLE_SID.ora
host echo rm $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora
host echo rm $ORACLE_HOME/dbs/orapw$ORACLE_SID

