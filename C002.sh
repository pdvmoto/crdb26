#!/bin/sh

# C002.sh - create minimalistic database, slightly improved
#
# Note: the new ORACLE_SID is the name of the script. 
# we carry that name as $ORACLE_SID everywhere where it is needed.
#
# todo:
# - SED-edit the init file and copy it to dbs
# 

ORACLE_SID="$(basename "$0")"
ORACLE_SID="${ORACLE_SID%.*}"
export ORACLE_SID

# generate a new init.ora from env_variables, absolute minimum
# initially I only need the db_name

cat <<EOF > init$ORACLE_SID.ora

# need this to prevent ORA-01506
db_name=$ORACLE_SID

# added file-destinations after first attempts

# set this explicitly.. add log-dest and flra if needed
control_files       = /opt/oracle/oradata/$ORACLE_SID/control01.ctl
db_create_file_dest = /opt/oracle/oradata

# check: this will create the diag if needed 
diagnostic_dest     = $ORACLE_BASE

# audit might be special, but best solution is Unified Auditing
audit_file_dest     = $ORACLE_BASE/audit

# note: core_dump seems set to diag by dflt, why not bdump and udump?
# and even though obsolete, they still got pointed flt to oracle_home ?
background_dump_dest  = $ORACLE_BASE/admin/$ORACLE_SID/bdump
user_dump_dest        = $ORACLE_BASE/admin/$ORACLE_SID/udump

# now some memory-settings, 
# I took those from the settings of the FREE conainers..
sga_target=1500M
pga_aggregate_target=512M

EOF

echo .
echo You are about to create a new container DB : $ORACLE_SID
echo .
echo Next: check the env-variables and the init.ora:
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
# creating paths, code from generated script
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

cp init${ORACLE_SID}.ora ${ORACLE_HOME}/dbs/

# need a pwdfile, if only to be able to connect SQLDev for inspection
orapwd file=${ORACLE_HOME}/dbs/orapw${ORACLE_SID} \
  password=oracle   \
  force=y format=12

# now go do the SQL..

sqlplus /nolog <<EOF

conn / as sysdba 

set echo on

startup nomount 

prompt .
prompt Startup nomount done, now creating database... 
prompt still with the simples command possible
prompt .

create database $ORACLE_SID ;

prompt .
prompt DB creation done, now showing pdbs and some info ... 
prompt .

show pdbs

set echo off

@chk_crdb1

-- @chk_early

EOF

echo .
echo Database $ORACLE_SID created...
echo .
echo Suggest to check tiny datafiles and dflt parameters 
echo .
read -t15 -p "Please Check" abc
echo .

exit 

