set heading off
set feedback off
set verify off

conn / as sysdba 

shutdown abort 

startup mount 

spool abc.rm

host echo '#!'$0

select 'rm ' || name from v$tempfile ;

select 'rm ' || name from v$datafile ;

select 'rm ' || member from v$logfile ;

select 'rm ' || name from v$controlfile ;

spool off

shutdown abort 

host echo Instance shutdown, now check and use abc.rm to remove db-files
