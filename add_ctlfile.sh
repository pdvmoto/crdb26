#!/bin/ksh

cat<<EOF> dothis.sql
set linesize 2048;
column ctl_files NEW_VALUE ctl_files;
select concat('control_files=''', concat(replace(value, ', ', ''','''), '''')) ctl_files from v\$parameter where name ='control_files';
host echo &ctl_files >>${ORACLE_HOME}/dbs/init${ORACLE_SID}.ora
EOF

sqlplus / as sysdba<<EOF
@dothis
EOF

read -t15 -p"check the contents of init.ora.
