--
-- 4_crdb : create one pdb (always try >1 to have multi-test)
--
-- todo/questions
--      check name of pluggable as &1
--      consider using 42_reopenpdb Arg1
--
-- stmnts copied in from :
--      plug_p1
--

define PDB_NAME="&1"

spool log_4_crdb_&&PDB_NAME..log append

host echo Start of 4_crdb_&&PDB_NAME at `date`

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

-- if needed, put notes below

spool off
