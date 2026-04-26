#!/bin/sh
#
# C000.sh - minimalistic database, just for demo, errors
#
# Note: the new ORACLE_SID is the basename of the script, without extention
# we carry that name as $ORACLE_SID everywhere where it is needed.
#
# todo:
#   - automatically report relevant data to stdout..
# 

ORACLE_SID="$(basename "$0")"
ORACLE_SID="${ORACLE_SID%.*}"
export ORACLE_SID

# need this to find (dflt) alert-file
export ORACLE_SID_LOWER=${ORACLE_SID,,}
export ALERT_FILE=$ORACLE_BASE/diag/rdbms/$ORACLE_SID_LOWER/$ORACLE_SID/trace/alert_$ORACLE_SID.log

# skip on first demo
# generate a new init.ora from env_variables, absolute minimum

# cat <<EOF > init$ORACLE_SID.ora
# 
# need this to prevent ORA-01506
# db_name=$ORACLE_SID
#  
# EOF

echo .
echo You are about to create a new CDB : $ORACLE_SID
echo .
echo Check the env-variables and the init.ora:
echo .
echo "ORACLE_BASE= " $ORACLE_BASE
echo "ORACLE_HOME= " $ORACLE_HOME
echo .
echo "ORACLE_SID=  " $ORACLE_SID
echo . 
ls -l init${ORACLE_SID}.ora
echo .
read -p "Control-C to cancel, if correct hit enter..." -t 10 abc
echo . 

#
# creating paths, code from older-version of dbca-generated script
#
OLD_UMASK=`umask`
umask 0027
mkdir -p /opt/oracle
mkdir -p /opt/oracle/admin
mkdir -p /opt/oracle/admin/${ORACLE_SID}/dpdump
mkdir -p /opt/oracle/admin/${ORACLE_SID}/pfile
mkdir -p /opt/oracle/admin/${ORACLE_SID}/scripts
mkdir -p /opt/oracle/audit
mkdir -p /opt/oracle/product/26ai/dbhome_1/dbs
mkdir -p /opt/oracle/oradata
mkdir -p /opt/oracle/oradata/${ORACLE_SID}
umask ${OLD_UMASK}

# cp init${ORACLE_SID}.ora ${ORACLE_HOME}/dbs/

# we need a pwdfile, or do we? 
# stricktly, you can do without
# but without pwdfile you can not connect-sys from SQLDeveloper..
orapwd file=${ORACLE_HOME}/dbs/orapw${ORACLE_SID} \
  password=oracle   \
  force=y format=12

# now do the SQL..

sqlplus /nolog <<EOF

set feedback on
set echo on

conn / as sysdba 

startup nomount 

host touch $ORACLE_HOME/dbs/init$ORACLE_SID.ora

startup nomount

host echo "db_name = " $ORACLE_SID > $ORACLE_HOME/dbs/init$ORACLE_SID.ora

startup nomount 

set echo off

prompt .
prompt Startup nomount requires an existing pfile, with at least the DB_NAME in it...
prompt .

host read -t15 -p " Instance started, now Create ..." abc

prompt .
prompt .
set echo on

create database $ORACLE_SID ;

set echo off

prompt .
prompt DB creation done, now showing pdbs and some info ... 
prompt .

show pdbs

prompt .
prompt . 

set echo off

@chk_early

EOF

echo .
echo Database $ORACLE_SID created...
echo Time elapsed is $SECONDS
echo .
echo Suggest to check tiny datafiles and dflt parameters 
echo .
read -t15 -p "Please Check, next is tail-alert.log" abc
echo .

tail -n30 $ALERT_FILE

exit 

