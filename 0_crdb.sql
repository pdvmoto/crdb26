
-- 0_crdb.sql: sript to call others 

set verify off

-- get passwords from script.
@accpwds

-- ACCEPT sysPassword CHAR PROMPT 'Enter new password for SYS: ' HIDE
-- ACCEPT systemPassword CHAR PROMPT 'Enter new password for SYSTEM: ' HIDE
-- ACCEPT pdbAdminPassword CHAR PROMPT 'Enter new password for PDBADMIN: ' HIDE

--
-- create the pwd file in default location
--
-- todo: 
--	- make sript runnable from any location by keeping pwd ?
--

spool 0_crdb append 

set echo on

connect / as sysdba 

-- host command must be 1 line inside sqlplus ... 
host ${ORACLE_HOME}/bin/orapwd file=${ORACLE_HOME}/dbs/orapw${ORACLE_SID} password=&&sysPassword force=y format=12

-- should we give a path ? (rather not, dont limit where we run from)
-- @${ORACLE_BASE}/admin/${ORACLE_SID}/scripts/1_crdb.sql

@1_crdb.sql

prompt .
prompt 1_crdb.sql: done. DB created
prompt .
prompt next is Files (1 user tablepace) and Catalog
prompt .

-- if needed, just test 1_crdb
-- spool off
-- exit

connect / as sysdba 

@2_crdb_catalog.sql

prompt .
prompt 2_crdb_catalog.sql: done. Catalog created
prompt .
prompt next are components from 3_crdb
prompt . 

@3_crdb_comp.sql

exit 

