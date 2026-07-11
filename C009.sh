#!/bin/sh
#
# SID.sh - create minimalistic database, testing purposes for now
# 
# latest version: C009.sh: Single File to do it all..
#   Take sql-files and init.ora into SID.sh, then create them on the fly if needed.
#
# The Conecpt:
#   - run this one file to create a database.
#   - the (hardcoded) SID in 1 place, the SID is FILE part of this FILE.sh 
#   - Other files: init, crdb1/2/3/4, and utilities will be Created if Needed.
#   - you can [optionally] inspect the created files before they run
#   - provide bespoke files (edited files), they wont be over-written.
#   - ask and allow interrupt before execution of script.
#
# the file that will be created (if not exist) are:
#   initSID.ora : and move it to dbs
#   accpwds.sql : the defines for passwords, you dont have to type..
#   1_crdb_create.sql
#   2_crdb_catalog.sql
#   3_crdb_comp.sql
#   4_crdb_pdb.sql
#   lock_accounts.sql
#   sec_cre.sql 
#   chk_crdb1.sql : first check after create, includes the "early" check
#   chk_postcre.sql : list some items at the end.. 
#   [todo] ctlfiles_to_init.sql: not needed, create spfile earlier.
#
# And some utilities:
#   sec_cre.sql : measure time since db-creation
#   chk_crdb1.sql : some checks
#   chk_early.sql : similar checks
#   ctlfiles_to_init.sql : can be used to add to pfile
#
# Concept is 
# 1) to generate the script (with non hardcoded SID in them): mk_file()
# 2) ask user to execute or just keep/view the scripts
# 3) if no read-input given: just execute and create the db: do_file()
# 4) spooled output to log_SID.log or to individual files ?
#
# Note: the new ORACLE_SID is the name of this script. 
# we set that name as $ORACLE_SID and carry it wherever it is needed.
#
# todo:
#  - lots of ideas, lot of things to try. see blogs, notes.
#  - include an option to stop+review. 
#  - allow bespoke-code: do not generate any script if already exist
#  - including a master-sql to run the generated scripts: SID.do ? 
#  - some files are quoted-EOF, others are expanded-EOF (with SID)
#  - the creation of directories is stil messy, improve if possible
#  - [useful?] include a "rm_SID" script to shutdown + cleanup ? 
#  - allow for a Env-var to contain additional PDBs (space-separated?)
#  - time the various stages: mk_files, execute..  and report duration
#  - note: to have "set echo on" work : cat <<EOF> 1_crdb.sql 
#	   This would make for better log- and traceablility.. 
#

# set -v -x 

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
# using EOF and not 'EOF' so I can use env-vars to include info
##############################################################################
#
# generate a new, minimalistid, init.ora
# initially I only needed the db_name
# later I added some of the parameters from DBCA 
# and some from myself
#
# note: mk_init uses a convential EOF so the ENV-vars can expand
#   other functions may use a quoted-EOF to include Dollar-signs.
#
# noteL: You can and should Experiment here.

f_mk_init_ora()
{

# inlcude a check-exist, dont overwrite existing file

echo $0 : "Generating init${ORACLE_SID}.ora ..."

cat <<EOF > init${ORACLE_SID}.ora
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
# note conventional here-doc with EOF, 
#   need to escape for : PDB\$SEED 
#
#
# Big Advantages of generating the file: 
# 1) everything is in ONE FILE 
# 2) set echo works, shows what is happening, and into log-file
# .) ..
# 
# ######## leftovers: save a copy of the  removed options #####
# MAXINSTANCES      8
# MAXLOGHISTORY     1
# MAXLOGFILES      16
# MAXLOGMEMBERS     3
# MAXDATAFILES   1024
#
#########################################################################
f_mk_1_crdb_create()
{

echo $0 : "Generating 1_crdb_create.sql ..."

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


#########################################################################
# Generate script 2_
#
#########################################################################
f_mk_2_crdb_catalog_OLD()
{

echo $0 : "Generating 2_crdb_catalog.sql ..."

cat << EOF > 2_crdb_catalog.sql 

-- 2_crdb : contains the db-files and db-catalog parts 
-- 
-- todo/questions
--  - why the ";"  behind the script ?
--  - why does catctlpl takes n=4, and catcon takes n=1
--  - can we write to ALERT already in between steps
--  - can we leave out the -d option at catctl.pl ?
--

spool log_2_crdb_catalog.log append

-- pick up defined passwords
@accpwds


-- from CreatDBFiles.sql: add a dflt-USER tablespace to CDB --
-- but in the latest SID.sh, I have the USERS tablespace included in the initial create.
-- so skip the create.

SET VERIFY OFF

connect "SYS"/"&&sysPassword" as SYSDBA

set echo off
set doc off

-- tablespace is now created at db-create time.
-- even the alter seems un-necessary.
ALTER DATABASE DEFAULT TABLESPACE "USERS";

-- from CreateDBCatalog: some scripts: --
--   catctl + catcon, doing catpcat, owminst, pubbld, pubdel, helpbld:

-- start with some Defines to shorten the commands, define CATCTL and CATCON
-- notice how -l sends lofiles to /tmp
-- notice how catctl does not have a -v

DEFINE CATCTL="\$ORACLE_HOME/perl/bin/perl \$ORACLE_HOME/rdbms/admin/catctl.pl -n 2 -l /tmp "
DEFINE CATCON="\$ORACLE_HOME/perl/bin/perl \$ORACLE_HOME/rdbms/admin/catcon.pl -n 2 -l /tmp -v "

prompt .
prompt catctl and catcon ...
prompt .
prompt &&CATCTL
prompt &&CATCON
prompt .

-- host-read only works form called sql-script, not from heredoc.
host read -t 15 -p " check catctl catcon " abc

-- these alter-stmnts were in generated script, hence I coped them in, not sure if useful:
alter session set "_oracle_script"=true;
alter pluggable database PDB\$SEED close;
alter pluggable database PDB\$SEED open;

-- in the generatd script, the last file didnt have $OH in front of it ?
-- so I left it out here as well.
-- can probably be simplified, but nothing in this command is too system-specific
host &&CATCTL -u "SYS"/"&&sysPassword" -icatpcat -c 'CDB\$ROOT PDB\$SEED' -a  -d \$ORACLE_HOME/rdbms/admin  rdbms/admin/catpcat.sql;

-- catcon: defaults to CDB + All PDBs, so leave out -c
-- catcon: the dflts for -U and -u are "/ as internal" hence only specify -u if not sys

host &&CATCON -b owminst                                 \$ORACLE_HOME/rdbms/admin/owminst.plb;

host &&CATCON -b pupbld   -u  SYSTEM/&&systemPassword    \$ORACLE_HOME/sqlplus/admin/pupbld.sql;

-- that one trigger...
host &&CATCON -b pupdel                                  \$ORACLE_HOME/sqlplus/admin/pupdel.sql;

-- the generated script did a reconnect..

connect "SYS"/"&&sysPassword" as SYSDBA

-- note: the -a option is vague, I dutyfully copied it from generated script.
-- Martin Berger (berx) dug in  and found it is probably windows or GUI related

host &&CATCON -b hlpbld                           -a 1   \$ORACLE_HOME/sqlplus/admin/help/hlpbld.sql;

prompt .
prompt  end of components from Files and Catalog,
prompt  consider adding some checks..
prompt .

spool off

-- end of script 2

EOF

echo .
echo $0 : created the script 2_crdb_catalog.sql

}

################ end of f_mk_2_crdb_catalog #######################################


f_mk_3_crdb_comp_OLD () 
{

echo $0 : "Generating 3_crdb_comp.sql ..."

cat << EOF > 3_crdb_comp.sql

-- 3_crdb : contains the various components and post creation
--
-- generated by $0 at `date` 
--
-- todo/questions
--  - why the ";"  behind the script ?
--  - put the defines for CATCTL and CATCON in separate file
--  - why so many reconnects ?
--  - sinds v21, no more ..
--
-- stmnts copied in from :
--  JServer.sql
--  context.sql
--  cwmlite.sql
--  spatial.sql
--  CreateClustDBViews.sql
--  lockAccount.sql
--  postDBCreation.sql
--

spool log_3_crdb_catalog.log append

host echo Start of 3_crdb_comp at \`date\`

-- pick up defined passwords
@accpwds

-- JServeer...

SET VERIFY OFF

connect "SYS"/"&&sysPassword" as SYSDBA

set echo on

-- start with some Defines to shorten the commands, define RCTL and RCON
-- notice how -l sends lofiles to /tmp
-- notice how catctl does not have a -v

/****
prompt .
prompt try disabling MZ processes to go faster.
prompt .

BEGIN
  DBMS_AUTO_TASK_ADMIN.DISABLE(
    client_name => 'sql tuning advisor',
    operation   => NULL,
    window_name => NULL);
END;
/

host read -t10 -p "disabled mz processes?" abc
***/

-- Define how to run catctl.pl and catcon.pl

DEFINE CATCTL="\$ORACLE_HOME/perl/bin/perl \$ORACLE_HOME/rdbms/admin/catctl.pl -n 2 -l /tmp "
DEFINE CATCON="\$ORACLE_HOME/perl/bin/perl \$ORACLE_HOME/rdbms/admin/catcon.pl -n 2 -l /tmp -v "

-- first: jserver
-- why do all script re-connect ?

connect "SYS"/"&&sysPassword" as SYSDBA
set echo on

host &&CATCON -b  initjvm         \$ORACLE_HOME/javavm/install/initjvm.sql;

host &&CATCON -b  initxml         \$ORACLE_HOME/xdk/admin/initxml.sql;

host &&CATCON -b  xmlja           \$ORACLE_HOME/xdk/admin/xmlja.sql;

host &&CATCON -b  catjava         \$ORACLE_HOME/rdbms/admin/catjava.sql;

-- next context
-- why reconnect so often ?
SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on

host &&CATCON -b catctx    -a 1   \$ORACLE_HOME/ctx/admin/catctx.sql 1Xbkfsdcdf1ggh_123 1SYSAUX 1TEMP 1LOCK ;
host &&CATCON -b dr0defin  -a 1   \$ORACLE_HOME/ctx/admin/defaults/dr0defin.sql 1\"AMERICAN\";
host &&CATCON -b dbmsxdbt         \$ORACLE_HOME/rdbms/admin/dbmsxdbt.sql;

-- cwmlite

SET VERIFY OFF
set echo on
connect "SYS"/"&&sysPassword" as SYSDBA

host &&CATCON -b  olap     -a 1  \$ORACLE_HOME/olap/admin/olap.sql 1SYSAUX 1TEMP;

-- next: spatial

-- you are here


-- end of script 3

EOF

echo .
echo $0 : created the script 3_crdb_comp.sql

}

################ end of f_mk_3_crdb_comp #######################################

#
# inlcude new code funcitons here
#


################ mkdirs #######################################
#
# mkdirs..
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
# optionally: do no generate, if file(s) already exist
#
f_mk_init_ora

# the pwdfile, Always overwritten.
#
f_mk_pwdfile

# out-comment the cp to allow to keep existing file
cp init${ORACLE_SID}.ora ${ORACLE_HOME}/dbs/

#
# generate create-stmnts and catalog
#
f_mk_1_crdb_create
f_mk_2_crdb_catalog
f_mk_3_crdb_comp
f_mk_4_crdb_pdbs

# 
# now list and ask for confirmation
#

# testing
exit

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
# echo for now, exit
# echo .
# exit

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
