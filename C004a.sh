#!/bin/sh

# C002a.sh - create minimalistic database, C002-edited
#
# Note: the new ORACLE_SID is the name of the script. 
# we carry that name as $ORACLE_SID everywhere where it is needed.
#
# todo:
# - SED-edit the init file and copy it to dbs: better use cat<<EOF
# 

ORACLE_SID="$(basename "$0")"
ORACLE_SID="${ORACLE_SID%.*}"
export ORACLE_SID

# #######################  Create INIT . ORA  ###################
# generate a new init.ora from env_variables, absolute minimum
# initially I only need the db_name
# later I added some tweaks to speed: control_mngmt=none

cat <<EOF > init$ORACLE_SID.ora

# need this to prevent ORA-01506
db_name=$ORACLE_SID

# added file-destinations after first attempts

# set this explicitly.. add log-dest and flra if needed
control_files       = /opt/oracle/oradata/$ORACLE_SID/control01.ctl
# db_create_file_dest = /opt/oracle/oradata
  db_create_file_dest = /tmp/oradata/

# check: this will create the diag if needed 
# diagnostic_dest     = $ORACLE_BASE
  diagnostic_dest     = /tmp/oradiag/

# reduce statistics activity during startup
# check that basic leads to timed_statistics=false
# so setting typical or all will also initiate timed_statistics=true
control_management_pack_access=NONE
# statistics_level=BASIC

# audit might be special, but best solution is Unified Auditing
# audit_file_dest     = $ORACLE_BASE/audit

# note: core_dump seems set to diag by dflt, why not bdump and udump?
# and even though obsolete, they still got pointed flt to oracle_home ?
# background_dump_dest  = $ORACLE_BASE/admin/$ORACLE_SID/bdump
# user_dump_dest        = $ORACLE_BASE/admin/$ORACLE_SID/udump

# now some memory-settings, 
# I took those 1500m from the settings of the FREE conainers..
sga_target=3500M
pga_aggregate_target=512M
processes=175

EOF

# ####################### end of init ###################

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
mkdir -p /opt/oracle/oradata
mkdir -p /opt/oracle/oradata/${ORACLE_SID}
mkdir -p /opt/oracle/admin
mkdir -p /opt/oracle/admin/${ORACLE_SID}/dpdump
mkdir -p /opt/oracle/admin/${ORACLE_SID}/pfile
mkdir -p /opt/oracle/admin/${ORACLE_SID}/scripts
mkdir -p /opt/oracle/audit
mkdir -p /opt/oracle/product/26ai/dbhome_1/dbs
umask ${OLD_UMASK}

cp init${ORACLE_SID}.ora ${ORACLE_HOME}/dbs/

# need a pwdfile, if only to be able to connect SQLDev for inspection
orapwd file=${ORACLE_HOME}/dbs/orapw${ORACLE_SID} \
  password=oracle   \
  force=y format=12

# now go do the SQL..

sqlplus /nolog <<EOF

conn / as sysdba 

@accpwds

set echo on

startup nomount 

prompt .
prompt Startup nomount done, now creating database... 
prompt still with the simples command possible
prompt .

create database $ORACLE_SID 
  SET DEFAULT BIGFILE TABLESPACE
    DATAFILE SIZE 1G  AUTOEXTEND ON  NEXT 201M  MAXSIZE UNLIMITED
      EXTENT MANAGEMENT LOCAL
  SYSAUX 
    DATAFILE SIZE 1G  AUTOEXTEND ON  NEXT 201M  MAXSIZE UNLIMITED
  SMALLFILE DEFAULT TEMPORARY TABLESPACE TEMP
    TEMPFILE SIZE 100M AUTOEXTEND ON NEXT  51M MAXSIZE UNLIMITED
  SMALLFILE UNDO TABLESPACE "UNDOTBS1"
    DATAFILE SIZE 400M AUTOEXTEND ON NEXT  101M  MAXSIZE UNLIMITED
LOGFILE                   /* create groups of larger files */ 
  GROUP 1  SIZE 400M
, GROUP 2  SIZE 400M
, GROUP 3  SIZE 400M
enable pluggable database /* enable+seed+sizes+localundo .. all 1 spec */ 
seed                      /* pre-emptively size these, undo dflt 100?  */
    SYSTEM   DATAFILES SIZE 500M AUTOEXTEND ON NEXT 101M MAXSIZE UNLIMITED
    SYSAUX   DATAFILES SIZE 500M autoextend on next 101M maxsize unlimited
  /* undo tablespace   /* leads to ora-30023, but how to create local undo?  * /
    UNDOTBS1 datrafile size 400M autoextend on next 101M maxsize unlimited
  ***/
LOCAL UNDO ON             /* this will create an undo_ts ? */
;

prompt .
prompt DB creation done, next showing pdbs and some info ... 
prompt .

show pdbs

prompt .
host read -t15 -p "Check create statement..." abc

set echo off

-- @chk_crdb1

@chk_early

-- exit to check
exit

connect / as sysdba

@2_crdb_catalog.sql

prompt .
prompt 2_crdb_catalog.sql: done. Catalog created
prompt .
prompt next are components from 3_crdb
prompt .

@3_crdb_comp.sql

EOF

echo .
echo Database $ORACLE_SID created...
echo .
echo Suggest to check tiny datafiles and dflt parameters 
echo .
read -t15 -p "Please Check" abc
echo .

exit 

