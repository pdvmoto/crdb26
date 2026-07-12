#!/bin/sh
#
# SID.sh - create minimalistic database, testing purposes for now
# 
# latest version: C009.sh: Single File to do it all..
#   I took the sql-files and init.ora and put them in to into SID.sh
#
# The Conecpt:
#   - you can run this one file to create a database.
#   - the (hardcoded) SID is in 1 place, the SID is FILE part of this FILE.sh 
#   - ORACLE_BNASE and _HOME have to be set correctly.
#   - all files: init, crdb1/2/3/4, and utilities will be Created if Needed.
#   - you can [optionally] inspect the created files before they run
#   - you can provide bespoke files (edited files), they wont be over-written.
#   - script will ask and allow interrupt before execution of script.
#
# the files that will be created (if not exist) are:
#   initSID.ora : and move it to dbs    (keep if exist) chk
#   pwdSID : and move to dbs            (always overwrite) todo
#   accpwds.sql : the defines for passwords, you dont have to type..
#   1_crdb_create.sql                   (always overwrite?) chk
#   2_crdb_catalog.sql                  (keep if exist)
#   3_crdb_comp.sql
#   4_crdb_pdb.sql                      (chk)
#   lock_accounts.sql
#
# And some utilities:
#   sec_cre.sql 
#   chk_crdb1.sql : first check after create, includes the "early" check
#   chk_postcre.sql : list some items at the end.. 
#   [todo] ctlfiles_to_init.sql: not needed, create spfile earlier.
#   [todo] f_mk_31_crdb_lock, and f_mk_accpwds
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
#  - devise a way to inlcud $CREATED_DT into the generated scripts
#  - allow bespoke-code: do not generate script if exist (done)
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


################### define all the variables ##################

ORACLE_SID="$(basename "$0")"
ORACLE_SID="${ORACLE_SID%.*}"
ORACLE_SID_LOWER=${ORACLE_SID,,}

export ORACLE_SID
export ORACLE_SID_LOWER

# define filenames
export INIT_ORA=init${ORACLE_SID}.ora
export CRDB1=1_crdb_create.sql
export CRDB2=2_crdb_catalog.sql
export CRDB3=3_crdb_comp.sql
export CRDB4=4_crdb_pdb.sql

export CREATED_DT=$(date +"%Y-%m-%d_%H-%M-%S")

echo . ....................... announce and prompt ....................
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

if [ -e ${INIT_ORA} ]; then
    echo File ${INIT_ORA} already exists. Keep Existing.
    return
fi

echo $0 : "Generating ${INIT_ORA} ..."

cat <<EOF > ${INIT_ORA}
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

echo $0 : "Generated ${INIT_ORA} ..."

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

if [ -e ${CRDB1} ]; then
    echo $0 : File ${CRDB1} already exists. Not overwriting.
    return
fi

echo $0 : "Generating $CRDB1 ..."

cat << EOF > $CRDB1

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

echo $0 : created the script ${CRDB1} 

}

# ######### end of function for 1_crdb_create ##########


##############################################################################
# Generate 2_crdb_catalog.sql
##############################################################################
f_mk_2_crdb_catalog()
{

  if [ -e ${CRDB2} ]; then
      echo $0 : File ${CRDB2} already exists. Not overwriting.
      return
  fi

  echo $0 : Generating ${CRDB2}.sql ... 

  # include check on exist

  cat >${CRDB2} <<'EOF'
-- 2_crdb : contains the db-files and db-catalog parts
--
-- todo/questions
--   - why the ";" behind the script?
--   - why does catctl.pl take n=4, and catcon takes n=1
--   - can we write to ALERT already in between steps
--   - can we leave out the -d option at catctl.pl?
--

spool log_2_crdb_catalog.log append

@accpwds

-- from CreateDBFiles.sql: add a default USERS tablespace to CDB.
-- In the latest script the USERS tablespace is already created,
-- so only keep the ALTER.

set verify off

connect "SYS"/"&&sysPassword" as SYSDBA

set echo off
set doc off

ALTER DATABASE DEFAULT TABLESPACE "USERS";

--
-- From CreateDBCatalog:
-- catctl + catcon, running catpcat, owminst, pupbld, pupdel and hlpbld.
--
-- start with some Defines to shorten the commands, define CATCTL and CATCON
-- notice how -l sends lofiles to /tmp
-- notice how catctl does not have a -v

define CATCTL="$ORACLE_HOME/perl/bin/perl $ORACLE_HOME/rdbms/admin/catctl.pl -n 2 -l /tmp "
define CATCON="$ORACLE_HOME/perl/bin/perl $ORACLE_HOME/rdbms/admin/catcon.pl -n 2 -l /tmp -v "

prompt .
prompt catctl and catcon ...
prompt .
prompt &&CATCTL
prompt &&CATCON
prompt .

host read -t 10 -p "Check catctl/catcon settings..." abc

-- These statements were in the generated script, hence I coped them in, not sure if useful:

alter session set "_oracle_script"=true;
alter pluggable database pdb$seed close;
alter pluggable database pdb$seed open;


-- in the generatd script, the last file didnt have $OH in front of it ?
-- so I left it out here as well.
-- can probably be simplified, but nothing in this command is too system-specific
host &&CATCTL -u "SYS"/"&&sysPassword" -icatpcat -c 'CDB$ROOT PDB$SEED' -a  -d $ORACLE_HOME/rdbms/admin  rdbms/admin/catpcat.sql;

-- catcon: defaults to CDB + All PDBs, so leave out -c
-- catcon: the dflts for -U and -u are "/ as internal" hence only specify -u if not sys

host &&CATCON -b owminst                                 $ORACLE_HOME/rdbms/admin/owminst.plb;

host &&CATCON -b pupbld   -u  SYSTEM/&&systemPassword    $ORACLE_HOME/sqlplus/admin/pupbld.sql;

                                                         -- that one trigger...
host &&CATCON -b pupdel                                  $ORACLE_HOME/sqlplus/admin/pupdel.sql;

-- the generated script did a reconnect..

connect "SYS"/"&&sysPassword" as SYSDBA

-- note: the -a option is vague, I dutyfully copied it from generated script.
-- Martin Berger (berx) dug in  and found it is probably windows or GUI related

host &&CATCON -b hlpbld                           -a 1   $ORACLE_HOME/sqlplus/admin/help/hlpbld.sql;

prompt .
prompt End of Files and Catalog phase.
prompt Consider adding some verification checks here.
prompt .

spool off
EOF
}

######### end of f_mk_2_crdb_catalog #### 


##############################################################################
# Generate 3_crdb_comp.sql
##############################################################################
f_mk_3_crdb_comp()
{

  if [ -e ${CRDB3} ]; then
      echo $0 : File ${CRDB3} already exists. Not overwriting.
      return
  fi

  echo $0 : Generating ${CRDB3}.sql ... 

  # use a "quoted here doc" to preserve use of $, & and \ 

    cat >${CRDB3} <<'EOF'
-- 3_crdb : contains the various components and post creation
-- 
-- todo/questions
-- 	- why the ";"  behind the script ? 
--	- put the defines for CATCTL and CATCON in separate file
--	- why so many reconnects ? 
--	- sinds v21, no more .. 
-- 
-- stmnts copied in from :
--	JServer.sql
--	context.sql
--	cwmlite.sql
--	spatial.sql
--	CreateClustDBViews.sql
--	lockAccount.sql
--	postDBCreation.sql
-- 

spool log_3_crdb_catalog.log append

host echo Start of 3_crdb_comp at `date` 

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

DEFINE CATCTL="$ORACLE_HOME/perl/bin/perl $ORACLE_HOME/rdbms/admin/catctl.pl -n 2 -l /tmp "
DEFINE CATCON="$ORACLE_HOME/perl/bin/perl $ORACLE_HOME/rdbms/admin/catcon.pl -n 2 -l /tmp -v "

-- first: jserver
-- why do all script re-connect ? 

connect "SYS"/"&&sysPassword" as SYSDBA
set echo on

host &&CATCON -b  initjvm         $ORACLE_HOME/javavm/install/initjvm.sql;

host &&CATCON -b  initxml         $ORACLE_HOME/xdk/admin/initxml.sql;

host &&CATCON -b  xmlja           $ORACLE_HOME/xdk/admin/xmlja.sql;

host &&CATCON -b  catjava         $ORACLE_HOME/rdbms/admin/catjava.sql;

-- next context
-- why reconnect so often ? 
SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on

host &&CATCON -b catctx    -a 1   $ORACLE_HOME/ctx/admin/catctx.sql 1Xbkfsdcdf1ggh_123 1SYSAUX 1TEMP 1LOCK ;
host &&CATCON -b dr0defin  -a 1   $ORACLE_HOME/ctx/admin/defaults/dr0defin.sql 1\"AMERICAN\";
host &&CATCON -b dbmsxdbt         $ORACLE_HOME/rdbms/admin/dbmsxdbt.sql;

-- cwmlite 

SET VERIFY OFF
set echo on
connect "SYS"/"&&sysPassword" as SYSDBA

host &&CATCON -b  olap     -a 1  $ORACLE_HOME/olap/admin/olap.sql 1SYSAUX 1TEMP;

-- next: spatial 

SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on

host &&CATCON -b mdinst          $ORACLE_HOME/md/admin/mdinst.sql;

spool off

-- next  ClusterDBViews

SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on

host &&CATCON -b catclust         $ORACLE_HOME/rdbms/admin/catclust.sql;

host &&CATCON -b catfinal         $ORACLE_HOME/rdbms/admin/catfinal.sql;

-- next Lock Accounts, root + pdbseed

SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on

alter session set "_oracle_script"=true;
alter pluggable database pdb$seed close;
alter pluggable database pdb$seed open;

@lock_accounts

alter session set container=pdb$seed;

@lock_accounts

-- next: Post DB creation (after cdb + seed, before pdbs )

SET VERIFY OFF

-- Datapatch ?? 

host $ORACLE_HOME/OPatch/datapatch -skip_upgrade_check -db $ORACLE_SID;

connect "SYS"/"&&sysPassword" as SYSDBA

-- spfile: skip for now, I prefer doing this later manually
-- set echo on
-- create spfile='/opt/oracle/product/26ai/dbhome_1/dbs/spfilec2.ora' FROM pfile='/opt/oracle/admin/c2/scripts/init.ora';

connect "SYS"/"&&sysPassword" as SYSDBA

-- added curiosity check, invalid obj
@invldobj 

host &&CATCON -b utlrp            $ORACLE_HOME/rdbms/admin/utlrp.sql;

select comp_id, status from dba_registry;

shutdown immediate;

connect "SYS"/"&&sysPassword" as SYSDBA

startup ;

-- copied from postDBCreation.sql, but why is this ? 
select instance from v$thread where instance like 'UNNAMED_INSTANCE%';

prompt .
prompt  end of 3_crdb_components
prompt  consider adding some checks..
prompt . 

host echo End of 3_crdb_comp at `date` 

spool off

-- notes below

EOF

}


##############################################################################
# Generate 4_crdb_pdb.sql
##############################################################################
f_mk_4_crdb_pdb()
{

  if [ -e ${CRDB4} ]; then
      echo $0 : File ${CRDB4} already exists. Not overwriting.
      return
  fi

  echo $0 : Generating ${CRDB4}.sql ... 

  # check exit

  cat > ${CRDB4} <<'EOF'
--
-- 4_crdb : create one pdb (always try >1 to have multi-test)
--
-- new PDB is Arg1 (ampersand-1 in sqlplus)
-- Concatenated plug_PDB and post_PDBCreation,
-- Note that I left most of the seemingly useless selects and re-connects
-- in the script.
--

-- implement dflt ORCL here..
column 1 new_value 1 noprint
select '&1' "1" from dual;
define PDB_NAME=&1 "ORCL"

spool log_4_crdb_&&PDB_NAME..log append

host echo .
host echo Start of 4_crdb_&&PDB_NAME at `date`
host echo .
host read -t15 -p "About to create PDB &&PDB_NAME " abc

@accpwds

set verify off

connect "SYS"/"&&sysPassword" as SYSDBA

set echo on

CREATE PLUGGABLE DATABASE &&PDB_NAME
  ADMIN USER PDBADMIN IDENTIFIED BY "&&pdbadminPassword";

-- I kept the select..
select name
from v$containers
where upper(name) = '&&PDB_NAME';

alter pluggable database &&PDB_NAME open;
alter system register;

-- go into container and create temp_non_enc

alter session set container=&&PDB_NAME;

select con_id
from v$pdbs
where con_id > 1
  and upper(name)=upper('&&PDB_NAME');

select bigfile
from sys.cdb_tablespaces
where tablespace_name='TEMP'
  and con_id=0;

CREATE SMALLFILE TEMPORARY TABLESPACE TEMP_NON_ENC
  TEMPFILE SIZE 20M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

ALTER DATABASE DEFAULT TEMPORARY TABLESPACE TEMP_NON_ENC;

-- repeatable section: goto root, close pdb, reopen pdb, register

alter session set container=CDB$ROOT;
alter pluggable database &&PDB_NAME close immediate;
alter pluggable database &&PDB_NAME open;
alter system register;

-- drop and recreate temp

alter session set container=&&PDB_NAME;

drop tablespace TEMP including contents and datafiles;

CREATE SMALLFILE TEMPORARY TABLESPACE TEMP
  TEMPFILE SIZE 20M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

ALTER DATABASE DEFAULT TEMPORARY TABLESPACE TEMP;

-- reopen...

alter session set container=CDB$ROOT;
alter pluggable database &&PDB_NAME close immediate;
alter pluggable database &&PDB_NAME open;
alter system register;

alter session set container=&&PDB_NAME;

drop tablespace TEMP_NON_ENC including contents and datafiles;

-- keep the state, e.g. default the new PDB as OPEN

alter pluggable database &&PDB_NAME save state;

prompt .
prompt now include the stmnts from postPDBCreation...
prompt notice a lot of double stmts in there
prompt .

connect "SYS"/"&&sysPassword" as SYSDBA

alter session set container=&&PDB_NAME;

set echo on

CREATE BIGFILE TABLESPACE USERS
  LOGGING
  DATAFILE SIZE 7M
  AUTOEXTEND ON NEXT 1280K MAXSIZE UNLIMITED
  EXTENT MANAGEMENT LOCAL
  SEGMENT SPACE MANAGEMENT AUTO;

ALTER DATABASE DEFAULT TABLESPACE USERS;

host $ORACLE_HOME/OPatch/datapatch -skip_upgrade_check -db $ORACLE_SID -pdbs &&PDB_NAME;

prompt .
prompt .
host read -t15 -p "default USERS tablespace and opatch done...." abc

--
-- From here on the script does little more than reconnect and verify.
--

connect "SYS"/"&&sysPassword" as SYSDBA

select property_value
from database_properties
where property_name='LOCAL_UNDO_ENABLED';

connect "SYS"/"&&sysPassword" as SYSDBA

alter session set container=&&PDB_NAME;

set echo on

select tablespace_name
from cdb_tablespaces a,
     dba_pdbs b
where a.con_id = b.con_id
  and upper(b.pdb_name)=upper('&&PDB_NAME');

connect "SYS"/"&&sysPassword" as SYSDBA

alter session set container=&&PDB_NAME;

set echo on

select count(*)
from dba_registry
where comp_id='DV'
  and status='VALID';

show con_name;

alter session set container=&&PDB_NAME;

select count(a.username)
from cdb_users a,
     v$pdbs b
where a.con_id = b.con_id
  and a.username = upper('PDBADMIN')
  and upper(b.name)=upper('&&PDB_NAME');

show con_name;

-- the generated script contained these two... ???
alter session set container="CDB$ROOT";
alter session set container=CDB$ROOT;

prompt .
prompt post pdb-creation done.
prompt .

spool off
EOF
}

#### end of f_mk_4_crdb_pdb ### 


##############################################################################
# Generate scs_since_cre.sql
##############################################################################
f_mk_sec_cre()
{
    echo
    echo $0 : Generating sec_cre.sql ...

    cat > sec_cre.sql <<'EOF'
--
-- log seconds since "create database" to stdout.
-- useful during create-scripts, purely curiosity and speed measurement
--

-- trick for default
col themsg new_value 1
select null themsg from dual where 1=2;

column sec_cre format 999,999,999
column message format A50

select ( sysdate - created ) * 24 * 3600 as sec_cre,
       'sec_cre_msg=' || nvl('&1','dflt msg') as message
from   v$database
/
EOF
}

##############################################################################
# Generate chk_crdb1.sql
##############################################################################
f_mk_chk_crdb1()
{
    echo
    echo "Generating chk_crdb1.sql ..."

    cat > chk_crdb1.sql <<'EOF'
rem
rem checks after first crdb
rem

column con_id     format 9999
column mb_size    format 999999
column ts_name    format A20

column ctl_file   format A90
column log_file   format A90
column df_name    format A90
column tmp_file   format A90

column grp        format 999

column db_name    format A15
column pdb_name   format A15
column owner_name format A20

column dbid       format 999999999999
column guid       format A33
column omode      format A11
column restricted format A10

set linesize 170

-- no spool, bcse this script called from others already spooling

select con_id, dbid, name, log_mode, open_mode
from v$database;

select  con_id
      , name        pdb_name
      , open_mode   omode
      , restricted
      , dbid
      , guid
from v$pdbs;

select  ts.con_id
      , ts.name ts_name
      , ts.bigfile
from v$tablespace ts
order by ts.con_id, ts.ts#;

prompt .
prompt So far, the container (CDB) and the PDBs and tablespaces.
prompt
prompt Next: the files...
prompt .

host read -t15 -p "check the info above, next: the files.." abc

select con_id, name ctl_file
from v$controlfile;

select  l.con_id
      , l.group# grp
      , l.bytes/(1024*1024) mb_size
      , lf.member log_file
from v$logfile lf
   , v$log l
where l.con_id = lf.con_id
  and l.group# = lf.group#
order by l.group#;

select df.con_id
     , bytes/(1024*1024) mb_size
     , df.name df_name
from v$datafile df
order by df.con_id;

set feedback on

select df.con_id
     , bytes/(1024*1024) mb_size
     , df.name df_name
from v$tempfile df
order by df.con_id;

prompt .
prompt ...and the bonus-query: check how much is already there..
prompt .

set echo on

select o.owner# owner
     , u.name owner_name
     , count(*) cnt
from sys.obj$ o
   , sys.user$ u
where user# = owner#
group by o.owner#, u.name
order by o.owner#;

set echo off

prompt  also include chk_early.sql


EOF

}

##############################################################################
# Generate lock_accounts.sql
##############################################################################
f_mk_lock_accounts()
{
    echo
    echo "Generating lock_accounts.sql ..."

    cat > lock_accounts.sql <<'EOF'
--
-- original from lockAccounts, extracted into separate file,
-- statement was identical in both locations, hence extracted
-- called for CDB$ROOT and PDB$SEED
--

BEGIN
  FOR item IN (
      SELECT username,
             authentication_type
      FROM   dba_users
      WHERE  account_status IN ('OPEN', 'LOCKED', 'EXPIRED')
      AND    username NOT IN (
                 'SYS',
                 'SYSTEM',
                 'SYSRAC',
                 'XS$NULL'
             )
  )
  LOOP
    IF item.authentication_type = 'PASSWORD' THEN
      dbms_output.put_line('Locking and Expiring: ' || item.username);

      EXECUTE IMMEDIATE
          'alter user '
       || sys.dbms_assert.enquote_name(
             sys.dbms_assert.schema_name(item.username), FALSE)
       || ' password expire account lock';

    ELSE
      dbms_output.put_line('Locking: ' || item.username);

      EXECUTE IMMEDIATE
          'alter user '
       || sys.dbms_assert.enquote_name(
             sys.dbms_assert.schema_name(item.username), FALSE)
       || ' account lock';
    END IF;
  END LOOP;
END;
/
EOF
}


# youarehere


##################### utilities ######################
# create the utilities:  call functions to do so
# sec_cre, chk_crdb1, 31_crdb_lock_acc, ctl_to_init

echo $0 : Generating utilities...

f_mk_sec_cre
f_mk_chk_crdb1
f_mk_lock_accounts

# todo:
# f_mk_31_crdb_lock_acc
# f_mk_ctl_to_init
# f_mk_accpwd

echo $0 : Utilities created.


################ mkdirs, Real Work starts Here #######################################
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

# 
# generate init and copy it to location
# optionally: do no generate, if file(s) already exist
#
f_mk_init_ora

# can out-comment the cp to allow to keep existing file in dbs
cp ${INIT_ORA} ${ORACLE_SID}.ora ${ORACLE_HOME}/dbs/

# the pwdfile, later. Always overwritten.
#
# f_mk_pwdfile

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

# just testing
exit


######################### for real ##################
#
# consider functions: 
# do_1
# do_2
# do_3
# etc.. but would it add something ?

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

read -t10 -p"DB Create done, control-C to stop..." abc

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
