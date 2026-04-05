
-- C1.sql: sript to call others 

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

--
@${ORACLE_BASE}/admin/${ORACLE_SID}/scripts/1_crdb.sql

echo Exit  after CDBhere

exit 

@/opt/oracle/admin/c2/scripts/CreateDBFiles.sql
@/opt/oracle/admin/c2/scripts/CreateDBCatalog.sql
@/opt/oracle/admin/c2/scripts/JServer.sql
@/opt/oracle/admin/c2/scripts/context.sql
@/opt/oracle/admin/c2/scripts/cwmlite.sql
@/opt/oracle/admin/c2/scripts/spatial.sql
@/opt/oracle/admin/c2/scripts/CreateClustDBViews.sql
@/opt/oracle/admin/c2/scripts/lockAccount.sql
@/opt/oracle/admin/c2/scripts/postDBCreation.sql
@/opt/oracle/admin/c2/scripts/PDBCreation.sql
@/opt/oracle/admin/c2/scripts/plug_p1.sql
@/opt/oracle/admin/c2/scripts/postPDBCreation_p1.sql
@/opt/oracle/admin/c2/scripts/plug_p2.sql
@/opt/oracle/admin/c2/scripts/postPDBCreation_p2.sql
