
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

-- keep this as smalles example.
-- then grow it to include options and datafile sizes.
-- original: all smallfiles ??
CREATE DATABASE C0 ;

-- check files..
-- and show sizes for cdb$root and pdb$seed
-- the undo-tablerspace = sys_undo 
-- all files smallfile and dictionary..
-- but try anyway..
@chk_crdb1

set echo off

prompt .
prompt End of 1_crdb.sql
prompt .

host read -t15 -p "CRDB-1 is now done. verify... " abc

spool off
