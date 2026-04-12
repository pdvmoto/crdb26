--
-- 4_crdb : create one pdb (always try >1 to have multi-test)
--
-- todo/questions
--      check name of pluggable as &1, set dflt to ORCL
--      consider using 42_reopenpdb Arg1
-- 	inspect postPDB creation.. why all the work: (and include it here..)
--
-- stmnts copied in from :
--      plug_p1
--

-- implement dflt ORCL here..
column 1 new_value 1 noprint
select '&1' "1" from dual ;
define PDB_NAME=&1 "ORCL"

-- define PDB_NAME="&1"

spool log_4_crdb_&&PDB_NAME..log append

host echo .
host echo Start of 4_crdb_&&PDB_NAME at `date`
host echo .
host read -t15 -p "About to create PDB &&PDB_NAME " abc


@accpwds

SET VERIFY OFF

connect "SYS"/"&&sysPassword" as SYSDBA

set echo on

CREATE PLUGGABLE DATABASE &&PDB_NAME
  ADMIN USER PDBADMIN IDENTIFIED BY "&&pdbadminPassword" ROLES=(CONNECT)
   PARALLEL  file_name_convert=NONE  STORAGE INHERIT;

select name from v$containers where upper(name) = '&&PDB_NAME';
alter pluggable database &&PDB_NAME open;
alter system register;

-- go into container and create temp_non_enc

ALTER SESSION SET CONTAINER = &&PDB_NAME;
select con_id from v$pdbs where con_id > 1 and upper(name)=upper('&&PDB_NAME') ;
SELECT bigfile FROM sys.cdb_tablespaces WHERE tablespace_name='TEMP' AND CON_ID=0;

CREATE SMALLFILE TEMPORARY TABLESPACE TEMP_NON_ENC
  TEMPFILE SIZE 20M AUTOEXTEND ON NEXT  10M MAXSIZE UNLIMITED;
ALTER DATABASE DEFAULT TEMPORARY TABLESPACE "TEMP_NON_ENC";

-- repeatable section: goto root, close pdb, repoen pdb, register.

alter session set container=cdb$root;
ALTER PLUGGABLE DATABASE &&PDB_NAME CLOSE IMMEDIATE;
alter pluggable database &&PDB_NAME open;
alter system register;

-- drop and re-create temp

ALTER SESSION SET CONTAINER = &&PDB_NAME;
drop tablespace TEMP including contents and datafiles;
CREATE SMALLFILE TEMPORARY TABLESPACE TEMP
  TEMPFILE SIZE 20M AUTOEXTEND ON NEXT  10M MAXSIZE UNLIMITED;
ALTER DATABASE DEFAULT TEMPORARY TABLESPACE "TEMP";

-- re-open...
alter session set container=cdb$root;
ALTER PLUGGABLE DATABASE &&PDB_NAME CLOSE IMMEDIATE;
alter pluggable database &&PDB_NAME open;
alter system register;

ALTER SESSION SET CONTAINER = &&PDB_NAME;
drop tablespace TEMP_NON_ENC including contents and datafiles;

-- verify by selecting temp-tablespaces and files ?

prompt .
prompt now include the stmnts from postPDBCreation...  
prompt notice a lot of double stmts in there  
prompt .

connect "SYS"/"&&sysPassword" as SYSDBA
alter session set container=&&PDB_NAME;

set echo on

-- why ?
CREATE BIGFILE TABLESPACE "USERS" LOGGING  DATAFILE  SIZE 7M AUTOEXTEND ON NEXT  1280K MAXSIZE UNLIMITED  EXTENT MANAGEMENT LOCAL  SEGMENT SPACE MANAGEMENT  AUTO;
ALTER DATABASE DEFAULT TABLESPACE "USERS";

host $ORACLE_HOME/OPatch/datapatch -skip_upgrade_check -db $ORACLE_SID -pdbs &&PDB_NAME;

prompt .
prompt .
host read -t15 -p "default USERS tablespace and opatch done...." abc 

connect "SYS"/"&&sysPassword" as SYSDBA

select property_value from database_properties where property_name='LOCAL_UNDO_ENABLED';

connect "SYS"/"&&sysPassword" as SYSDBA

alter session set container=&&PDB_NAME;

set echo on

-- why ? 
select TABLESPACE_NAME from cdb_tablespaces a,dba_pdbs b 
where a.con_id=b.con_id and UPPER(b.pdb_name)=UPPER('&&PDB_NAME');

connect "SYS"/"&&sysPassword" as SYSDBA

alter session set container=&&PDB_NAME;

set echo on

Select count(*) from dba_registry where comp_id = 'DV' and status='VALID';

show con_name;
alter session set container=&&PDB_NAME ; 
select count(a.username) 
from cdb_users a, v$pdbs b 
where a.con_id=b.con_id 
and a.username=upper('PDBADMIN') 
and upper(b.name)=upper('&&PDB_NAME');

show con_name;

alter session set container="CDB$ROOT";
alter session set container=CDB$ROOT;

prompt .
prompt post pdb-creation done.
prompt .

-- if needed, put notes below

spool off
