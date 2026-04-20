#!/bin/sh

# C0.sh - minimalistic database, just for demo
#
# New ORACLE_SID is the name of the script.. 
# carry that name everywhere..
#
# todo:
# - SED-edit the init file and copy it to dbs
# 

ORACLE_SID="$(basename "$0")"
ORACLE_SID="${ORACLE_SID%.*}"
export ORACLE_SID

# generate a new init.ora from env_variables, absolute minimum

cat <<EOF > init$ORACLE_SID.ora

db_name=$ORACLE_SID

control_files       =/opt/oracle/oradata/$ORACLE_SID/control01.ctl

db_create_file_dest=$ORACLE_BASE/oradata
diagnostic_dest    =$ORACLE_BASE

processes=320
 
sga_target=2352m
pga_aggregate_target=784m

remote_login_passwordfile=EXCLUSIVE
 
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
mkdir -p /iopt/oracle/admin/${ORACLE_SID}/scripts
mkdir -p /opt/oracle/audit
mkdir -p /opt/oracle/product/26ai/dbhome_1/dbs
mkdir -p /opt/oracle/oradata
mkdir -p /opt/oracle/oradata/${ORACLE_SID}
umask ${OLD_UMASK}

cp init${ORACLE_SID}.ora ${ORACLE_HOME}/dbs/

# we need a pwdfile, or do we?
orapwd file=${ORACLE_HOME}/dbs/orapw${ORACLE_SID} \
  password=oracle   \
  force=y format=12

# now go do the SQL..

sqlplus /nolog <<EOF

conn / as sysdba 

set echo on

startup nomount 

create database $ORACLE_SID ;

show pdbs

EOF

echo .
echo Database $ORACLE_SID created...
echo .
echo Suggest to check datafiles (tiny) and parameters (dflts)
echo .
read -t15 -p "Please Check" abc
echo .

exit 

