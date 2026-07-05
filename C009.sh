#!/bin/sh
#
# SID.sh - create minimalistic database, testing purposes for now
# 
# latest version: C009.sh: take sql-files into SID.sh, create them on the fly
#
# Other files needed, now generated:
#   1_crdb_create.sql
#   2_crdb_catalog.sql
#   3_crdb_comp.sql
#   4_crdb_pdb.sql
#   lock_accounts.sql
#
# And some utilities:
#   sec_cre.sql
#   chk_crdb1.sql
#   chk_early.sql
#   ctlfiles_to_init.sql
#   
#
# Note: the new ORACLE_SID is the name of this script. 
# we set that name as $ORACLE_SID and carry it wherever it is needed.
#
# todo:
#  - lots of ideas, lot of things to try. see blogs, notes.
#  - generate 2_crdb, 3_crdb and 4_crdb on the fly, from 1 single SID.sh ? 
#  - to have "set echo on" work : cat <<EOF> 1_crdb.sql 
#	   This would make for better log- and traceablility.. 
#

# allow interrupt, notably on read -t15
trap 'echo; echo "Interrupted while processing $0 "; exit 130' INT

ORACLE_SID="$(basename "$0")"
ORACLE_SID="${ORACLE_SID%.*}"
ORACLE_SID_LOWER=${ORACLE_SID,,}

export ORACLE_SID
export ORACLE_SID_LOWER

export CREATED_DT=$(date +"%Y-%m-%d_%H-%M-%S")

echo .
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
echo "Create time= " $CREATED_DT
echo .
echo .
read -p "Check, and use Control-C to cancel, if correct hit enter..." -t10 abc
echo .


##############################################################################
# Generate INIT dot ORA ###########
##############################################################################
#
# generate a new, minimalistid, init.ora
# initially I only needed the db_name
# later I added some of the parameters from DBCA 
# and some from myself
#
# You can and should Experiment here.

f_mk_init_ora()
{
    echo "Generating init${ORACLE_SID}.ora ..."

    cat > "init${ORACLE_SID}.ora" <<EOF
#
# init.ora generated from $0 at ${CREATED_DT}
#

db_name              = ${ORACLE_SID}

                              # #### FILES ####

db_create_file_dest  = /opt/oracle/oradata

# db_recovery_file_dest      = /opt/oracle/fast_recovery_area
# db_recovery_file_dest_size = 21987m

control_files        = /opt/oracle/oradata/${ORACLE_SID}/controlfile/control01.ctl

diagnostic_dest      = ${ORACLE_BASE}

# audit_file_dest    = ${ORACLE_BASE}/audit

                              # #### MEMORY ####

sga_target           = 2500M
pga_aggregate_target = 512M

processes            = 200
open_cursors         = 300

                              # #### VARIOUS ####

remote_login_passwordfile = EXCLUSIVE

# undo_tablespace    = SYS_UNDOTS

# control_management_pack_access = NONE

EOF
}

# ######### end of function for ini.ora ##########


#########################################################################
# Generate script 1_crdb_create.sql
#
# notice escapes for pdb$seed : PDB\$SEED, can this be done more elegant
#
# Big Advantages: 
# 1) set echo works, shows what is happening, and into log-file
# 2) only download + transport 1 script
# 3) keep the n_crdb files for reference or editing ..
# 4) ..
#
#########################################################################
f_mk_1_create_sql()
{
cat << EOF > 1_crdb_create.sql 

-- pick up defined passwords
@accpwds

set echo on
set timing on
set verify off

startup nomount

set echo off

prompt .
prompt Startup nomount done, now creating database...
prompt still with the simplest command possible
prompt .

host sleep 10

set echo on

CREATE DATABASE ${ORACLE_SID}
EXTENT MANAGEMENT LOCAL
SET DEFAULT BIGFILE TABLESPACE
    DATAFILE SIZE 1200M AUTOEXTEND ON NEXT 101M MAXSIZE UNLIMITED
  SYSAUX
    DATAFILE SIZE 1000M AUTOEXTEND ON NEXT 101M MAXSIZE UNLIMITED
  DEFAULT TEMPORARY TABLESPACE TEMP
    TEMPFILE SIZE 200M AUTOEXTEND ON NEXT 101M MAXSIZE UNLIMITED
  UNDO TABLESPACE SYS_UNDOTS
    DATAFILE SIZE 500M AUTOEXTEND ON NEXT 101M MAXSIZE UNLIMITED
  DEFAULT TABLESPACE USERS
    DATAFILE SIZE 50M AUTOEXTEND ON NEXT 101M MAXSIZE UNLIMITED
CHARACTER SET AL32UTF8
NATIONAL CHARACTER SET AL16UTF16
LOGFILE
  GROUP 1 SIZE 500M,
  GROUP 2 SIZE 500M,
  GROUP 3 SIZE 500M
USER SYS IDENTIFIED BY "&&sysPassword"
USER SYSTEM IDENTIFIED BY "&&systemPassword"
ENABLE PLUGGABLE DATABASE
SEED
    SYSTEM DATAFILES SIZE 400M AUTOEXTEND ON NEXT 101M MAXSIZE UNLIMITED
    SYSAUX DATAFILES SIZE 400M AUTOEXTEND ON NEXT 101M MAXSIZE UNLIMITED
    LOCAL UNDO ON
;

show pdbs

-- first the resize undo of the CDB, if needed
-- alter tablespace SYS_UNDOTS resize 500M;
-- alter tablespace SYS_UNDOTS autoextend on next 101M maxsize unlimited;

-- now the PDB-SEED
alter pluggable database "PDB\$SEED" close;
alter pluggable database "PDB\$SEED" open;
alter session set container="PDB\$SEED";

alter tablespace SYS_UNDOTS resize 500M;
alter tablespace SYS_UNDOTS autoextend on next 101M maxsize unlimited;

-- back to CDB
alter session set container="CDB\$ROOT";

-- try saving on some effort here..
ALTER SYSTEM SET CONTROL_MANAGEMENT_PACK_ACCESS=NONE;

set echo off

EOF

echo $0 : created the script 1_crdb_create.sql

}

# ######### end of function for 1_crdb_create ##########


# creating paths, code from generated script
# note: consider using $ORACLE_BASE, $ORACLE_HOME, $ORACLE_DATA, $ORACLE_FLRA
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
mkdir -p /opt/oracle/oradata/${ORACLE_SID}/controlfile
umask ${OLD_UMASK}

# need a pwdfile, if only to be able to connect SQLDev for inspection
orapwd file=${ORACLE_HOME}/dbs/orapw${ORACLE_SID} \
  password=oracle   \
  force=y format=12

# ######## save a copy of the  removed options #####
# MAXINSTANCES      8
# MAXLOGHISTORY     1
# MAXLOGFILES      16
# MAXLOGMEMBERS     3
# MAXDATAFILES   1024


# 
# generate init and copy it to location
#
f_mk_init_ora

# out-comment the cp to allow to keep existing file
cp init${ORACLE_SID}.ora ${ORACLE_HOME}/dbs/

#
# generate create-stmnts
#
f_mk_1_create_sql

sqlplus /nolog <<EOF | tee log_${ORACLE_SID}.log

conn / as sysdba 

-- pick up defined passwords
@accpwds

-- run the script to Create Database
@1_crdb_create

prompt .
prompt DB creation done, now showing pdbs and some info ... 
prompt .

@sec_cre first_message_since_creation

host sleep 10

show pdbs

set echo off

@chk_crdb1

@chk_early

prompt .
prompt Exit for now. Add other script below later.
prompt .

exit

EOF

echo .
echo Created Database $ORACLE_SID
echo Elapsed $SECONDS
echo .

read -t15 -p"DB Create done, control-C to stop..." abc

# for testing.
echo for now, exit
echo .
exit

# reconnect
sqlplus /nolog <<EOF | tee -a log_${ORACLE_SID}.log

connect / as sysdba

-- script nr 2: catalog, and some other cmds from CreateDBCatalog

@2_crdb_catalog

set echo off
set feedb off

@sec_cre second message since creation
@sec_cre timing_of_2_crdb_catalog

prompt .
prompt 2_crdb_catalog.sql: done. Catalog created
prompt .
prompt next are components from 3_crdb_comp
prompt .

host sleep 10 

@3_crdb_comp

set echo off
set feedb off

@sec_cre third_message_since_creation
@sec_cre timing_of_3_crdb_comp

prompt .
prompt 3_crdb_comp.sql: components added, accounts locked, datapatch done
prompt no PDBs yet...
prompt .

EOF

echo .
echo Database $ORACLE_SID created...
echo .
echo Suggest to check datafiles and dflt parameters 
echo .
echo Next is 4_crdb_pdb.sql to create PDBs...
echo .
read -t15 -p "Please Check" abc
echo .

# reconnect
sqlplus /nolog <<EOF | tee -a log_${ORACLE_SID}.log

connect / as sysdba

-- script nr 4: add one or more pdbs
-- in this case: the old known values

@4_crdb_pdb freepdb1
@4_crdb_pdb orcl

set echo off
set feedb off

@sec_cre fourth message since creation
@sec_cre timing_of_4_crdb_pdb

prompt .
prompt 4_crdb_pdb.sql: done. two PDBs created
prompt .

EOF

echo .
echo Database $ORACLE_SID plus Two PDBs created...
echo .
echo Suggest to check datafiles and dflt parameters 
echo .
read -t15 -p "Please Check, and enjoy using your database..." abc
echo .
