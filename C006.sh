#!/bin/sh
#
# SID.sh - create minimalistic database, testing purposes for now
# 
# latest version: C006.sh
#
# Note: the new ORACLE_SID is the name of this script. 
# we set that name as $ORACLE_SID and carry it wherever it is needed.
#
# todo:
#  - lots of ideas, lot of things to try. see blogs, notes.
# 

# allow interrupt, notably on read -t15
trap 'echo; echo "Interrupted while processing $0 "; exit 130' INT

ORACLE_SID="$(basename "$0")"
ORACLE_SID="${ORACLE_SID%.*}"
ORACLE_SID_LOWER=${ORACLE_SID,,}

export ORACLE_SID
export ORACLE_SID_LOWER

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
echo .
read -p "Control-C to cancel, if correct hit enter..." -t10 abc
echo .


########## INIT dot ORA ###########
#
# generate a new init.ora from env_variables, absolute minimum
# initially I only needed the db_name
# later I added the parameters from DBCA as well
# can and Will Experiment here.

cat <<EOF > init$ORACLE_SID.ora
# init.ora generated from $0 at ${date}

db_name=$ORACLE_SID                     # need this to prevent ORA-01506

                                        # file-destinations, control where...
                                        # add log-dest and flra if needed
db_create_file_dest  = /opt/oracle/oradata

                                        # explicit controlfile, OMF later.
control_files        = /opt/oracle/oradata/$ORACLE_SID/controlfile/control01.ctl

diagnostic_dest      = $ORACLE_BASE     # this will create the diag if needed

# audit_file_dest      = $ORACLE_BASE/audit # consider unified auditing.

sga_target           = 2500M            # 1500M will fit inside FREE
pga_aggregate_target = 512M

undo_tablespace      = UNDOTBS1         # create-db uses this name

EOF

cp init${ORACLE_SID}.ora ${ORACLE_HOME}/dbs/

#
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

# now go do the SQL..

sqlplus /nolog <<EOF | tee log_${ORACLE_SID}.log

conn / as sysdba 

-- pick up defined passwords
@accpwds

set echo on
set timing on
set verify off

startup nomount 

set echo off

prompt .
prompt Startup nomount done, now creating database... 
prompt still with the simples command possible
prompt .

host sleep 10

set echo on

CREATE DATABASE ${ORACLE_SID}
EXTENT MANAGEMENT LOCAL   /* outcommenht to keep SYSTEM DICT, old plugins? */
SET DEFAULT BIGFILE TABLESPACE    /*  set sizes based on finished database */
    DATAFILE SIZE 1200M AUTOEXTEND ON NEXT   101M MAXSIZE UNLIMITED
  SYSAUX 
    DATAFILE SIZE 1000M AUTOEXTEND ON NEXT   101M MAXSIZE UNLIMITED
  DEFAULT TEMPORARY TABLESPACE TEMP
    TEMPFILE SIZE  200M AUTOEXTEND ON NEXT   101M MAXSIZE UNLIMITED
  UNDO TABLESPACE UNDOTBS1 
    DATAFILE SIZE  500M AUTOEXTEND ON NEXT   101M MAXSIZE UNLIMITED
  DEFAULT TABLESPACE USERS
    DATAFILE SIZE   50M AUTOEXTEND ON NEXT   101M MAXSIZE UNLIMITED
          CHARACTER SET AL32UTF8   /* dflt was US7ASCII.. so better specify */
 NATIONAL CHARACTER SET AL16UTF16  /* this was the dflt...                  */
LOGFILE 
  GROUP 1  SIZE 500M,
  GROUP 2  SIZE 500M,
  GROUP 3  SIZE 500M
USER SYS    IDENTIFIED BY "&&sysPassword"
USER SYSTEM IDENTIFIED BY "&&systemPassword"
ENABLE PLUGGABLE DATABASE
SEED                                                  /*  prevent resizes */
    SYSTEM DATAFILEs SIZE 400M AUTOEXTEND ON NEXT 101M MAXSIZE UNLIMITED
    SYSAUX DATAFILEs SIZE 400M AUTOEXTEND ON NEXT 101M maxsize unlimited
    LOCAL UNDO ON
;

show pdbs 

-- test resizing undo for seed (beware of $-vars in HereDoc)
-- I know I probably shouldnt, but space-management is an obsession
alter pluggable database "PDB\$SEED" close ; 
alter pluggable database "PDB\$SEED" open ;
alter session set container="PDB\$SEED" ;
alter tablespace UNDOTBS1 resize 500M ; 
alter tablespace UNDOTBS1 autoextend on next 101M maxsize unlimited; 
alter session set container="CDB\$ROOT" ; 

set echo off

prompt .
prompt DB creation done, now showing pdbs and some info ... 
prompt .

@sec_cre first_message_since_creation

host sleep 10

set echo on

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
echo End of $0 

read -t15 -p"DB Create done, control-C to stop..." abc

# reconnect
sqlplus /nolog <<EOF

connect / as sysdba

-- script nr 2: catalog, and some other cmds from CreateDBCatalog

@2_crdb_catalog

set echo off
set feedb off

@sec_cre fifth_message_since_creation
@sec_cre timing_of_2_crdb_catalog

prompt .
prompt 2_crdb_catalog.sql: done. Catalog created
prompt .
prompt next are components from 3_crdb
prompt .

host sleep 10 

@3_crdb_comp.sql

set echo off
set feedb off

@sec_cre sixth_message_since_creation
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

