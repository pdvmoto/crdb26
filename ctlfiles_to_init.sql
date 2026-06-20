
-- add the ctlfiles to the init file, ready to then create the spfile

set heading off
set linesize 2048;
set feedb off

column ctl_files NEW_VALUE ctl_files;

select concat('control_files=''', concat(replace(value, ', ', ''','''), '''')) ctl_files from v$parameter where name ='control_files';

host echo &ctl_files >>${ORACLE_HOME}/dbs/init${ORACLE_SID}.ora;

