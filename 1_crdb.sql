
spool log_1_crdb.log append

-- todo:
-- replace hardcoded SID by &1, default C1 ?
-- 
-- sizes: cdb-system and sysaux: 1G + 200M
-- sizes: cdb-undo: 300M + 100M
-- sizes: pdb :  system + sysaux : 500M + 100M 
-- sizes: pdb-undo : 300M + 100M
-- 
-- init.ora: bdump, cdump, udump to prevent OH from filling up

SET VERIFY 	OFF
set feedback  	on
set echo 	on

connect "SYS"/"&&sysPassword" as SYSDBA

set echo off
prompt .
prompt First Start, only works if init-file is present
prompt .

set timing on
set echo on

startup nomount 

CREATE DATABASE "C3"
  MAXINSTANCES 8
  MAXLOGHISTORY 1
  MAXLOGFILES 16
  MAXLOGMEMBERS 3
  MAXDATAFILES 1024
       DATAFILE SIZE 1G AUTOEXTEND ON NEXT 200M  MAXSIZE UNLIMITED
	  EXTENT MANAGEMENT LOCAL
SYSAUX DATAFILE SIZE 1G AUTOEXTEND ON NEXT 200M MAXSIZE UNLIMITED 
  SMALLFILE DEFAULT TEMPORARY TABLESPACE TEMP 
       TEMPFILE SIZE 103M AUTOEXTEND ON NEXT  50M MAXSIZE UNLIMITED
  SMALLFILE UNDO TABLESPACE "UNDOTBS1" 
       DATAFILE SIZE 200M AUTOEXTEND ON NEXT  100M  MAXSIZE UNLIMITED
  CHARACTER SET AL32UTF8
  NATIONAL CHARACTER SET AL16UTF16
  SET DEFAULT BIGFILE TABLESPACE 
LOGFILE 
  GROUP 1  SIZE 200M,
  GROUP 2  SIZE 200M,
  GROUP 3  SIZE 200M
USER SYS IDENTIFIED BY "&&sysPassword" 
USER SYSTEM IDENTIFIED BY "&&systemPassword"
enable pluggable database 
   SEED
   SYSTEM DATAFILES SIZE 200M AUTOEXTEND ON NEXT 100M MAXSIZE UNLIMITED
   SYSAUX DATAFILES SIZE 200M autoextend on next 100M maxsize unlimited
LOCAL UNDO ON
;

prompt .
prompt . DB Created
prompt .
host read -t 15 -p "hit enter to continue..." abc

CREATE DATABASE "C1-notyet"
MAXINSTANCES 8
MAXLOGHISTORY 1
MAXLOGFILES 16
MAXLOGMEMBERS 3
MAXDATAFILES 1024
DATAFILE SIZE 700M AUTOEXTEND ON NEXT  10240K MAXSIZE UNLIMITED
EXTENT MANAGEMENT LOCAL
SYSAUX DATAFILE SIZE 550M AUTOEXTEND ON NEXT  10240K MAXSIZE UNLIMITED
SMALLFILE DEFAULT TEMPORARY TABLESPACE TEMP TEMPFILE SIZE 20M AUTOEXTEND ON NEXT  640K MAXSIZE UNLIMITED
SMALLFILE UNDO TABLESPACE "UNDOTBS1" DATAFILE  SIZE 200M AUTOEXTEND ON NEXT  5120K MAXSIZE UNLIMITED
CHARACTER SET AL32UTF8
NATIONAL CHARACTER SET AL16UTF16
SET DEFAULT BIGFILE TABLESPACE
LOGFILE GROUP 1  SIZE 200M,
GROUP 2  SIZE 200M,
GROUP 3  SIZE 200M
USER SYS IDENTIFIED BY "&&sysPassword" USER SYSTEM IDENTIFIED BY "&&systemPassword"
enable pluggable database LOCAL UNDO ON;

-- keep this as smalles example.
-- then grow it to include options and datafile sizes.
-- original: all smallfiles ??
CREATE DATABASE C1
EXTENT MANAGEMENT LOCAL
DEFAULT TABLESPACE users
DEFAULT TEMPORARY TABLESPACE temp
UNDO TABLESPACE undotbs1
  CHARACTER SET AL32UTF8
ENABLE PLUGGABLE DATABASE
   SEED
   SYSTEM DATAFILES SIZE 40M AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED
   SYSAUX DATAFILES SIZE 40M;

--enable pluggable database 

set linesize 2048;

-- we have the ctl-file(s) defined in init-ora
-- 
-- column ctl_files NEW_VALUE ctl_files;
-- select concat('control_files=''', concat(replace(value, ', ', ''','''), '''')) ctl_files from v$parameter where name ='control_files';
-- set echo on
-- host echo &ctl_files >>/opt/oracle/admin/c2/scripts/init.ora;

-- check files..
@chk_crdb1

set echo off

prompt .
prompt End of 1_crdb.sql
prompt .

host read -t15 -p "CRDB-1 is now done. verify... " abc

spool off
