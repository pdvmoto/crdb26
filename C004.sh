#!/bin/sh
#
# SID.sh - create minimalistic database, testing purposes for now
#
# Note: the new ORACLE_SID is the name of the script. 
# we carry that name as $ORACLE_SID everywhere where it is needed.
#
# todo:
#  - lots of ideas
# 

# allow interrupt, notably on read -t15

trap 'echo; echo "Interrupted while processing $0 "; exit 130' INT

ORACLE_SID="$(basename "$0")"
ORACLE_SID="${ORACLE_SID%.*}"
ORACLE_SID_LOWER=${ORACLE_SID,,}

export ORACLE_SID
export ORACLE_SID_LOWER

########## INIT dot ORA ###########
#
# generate a new init.ora from env_variables, absolute minimum
# initially I only needed the db_name
# later I added the parameters from DBCA as well
# can and Will Experiment here.

cat <<EOF > init$ORACLE_SID.ora

                                        # need this to prevent ORA-01506
db_name=$ORACLE_SID

                                        # file-destinations, control where...
                                        # add log-dest and flra if needed
db_create_file_dest = /opt/oracle/oradata
control_files       = /opt/oracle/oradata/$ORACLE_SID/controlfile/control01.ctl

                                        # this will create the diag if needed 
diagnostic_dest     = $ORACLE_BASE

                                        # best solution is Unified Auditing
audit_file_dest     = $ORACLE_BASE/audit

                                        # memory settings, fit inside FREE
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
echo "ORACLE_SID=  " $ORACLE_SID ... "(" $ORACLE_SID_LOWER ")" 
echo . 
ls -l init${ORACLE_SID}.ora
echo .
read -p "Control-C to cancel, if correct hit enter..." -t10 abc
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

sqlplus /nolog <<EOF | tee log_$ORACLE_SID.log

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

@sec_cre first_message_since_creation

show pdbs

set echo off
set verify off

@sec_cre second_message_since_creation

@chk_crdb1

@sec_cre third_message_since_creation

@chk_early

@sec_cre fourth_message_since_creation


connect / as sysdba

@2_crdb_catalog.sql

prompt .
prompt 2_crdb_catalog.sql: done. Catalog created
prompt .
prompt next are components from 3_crdb
prompt .

@sec_cre fifth_message_since_creation

@3_crdb_comp.sql

@sec_cre sixth_message_since_creation

EOF

echo .
echo Database $ORACLE_SID created...
echo .
echo Suggest to check tiny datafiles and dflt parameters 
echo .
read -t15 -p "Please Check" abc
echo .

exit 

