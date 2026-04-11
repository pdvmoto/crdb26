

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

DEFINE CATCTL="$ORACLE_HOME/perl/bin/perl $ORACLE_HOME/rdbms/admin/catctl.pl -n 4 -l /tmp "
DEFINE CATCON="$ORACLE_HOME/perl/bin/perl $ORACLE_HOME/rdbms/admin/catcon.pl -n 1 -l /tmp -v "

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

-- first: jserver
-- why do all script re-connect ? 

connect "SYS"/"&&sysPassword" as SYSDBA
set echo on

host &&CATCON -b  initjvm  -c 'PDB$SEED CDB$ROOT' -U  "SYS"/"&&sysPassword"  $ORACLE_HOME/javavm/install/initjvm.sql;

host &&CATCON -b  initxml  -c 'PDB$SEED CDB$ROOT' -U  "SYS"/"&&sysPassword"  $ORACLE_HOME/xdk/admin/initxml.sql;

host &&CATCON -b  xmlja    -c 'PDB$SEED CDB$ROOT' -U  "SYS"/"&&sysPassword"  $ORACLE_HOME/xdk/admin/xmlja.sql;

host &&CATCON -b  catjava  -c 'PDB$SEED CDB$ROOT' -U  "SYS"/"&&sysPassword"  $ORACLE_HOME/rdbms/admin/catjava.sql;

-- next context
-- why reconnect so often ? 
SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on

host &&CATCON -b catctx    -c 'PDB$SEED CDB$ROOT' -U  "SYS"/"&&sysPassword"  -a 1   $ORACLE_HOME/ctx/admin/catctx.sql 1Xbkfsdcdf1ggh_123 1SYSAUX 1TEMP 1LOCK ;
host &&CATCON -b dr0defin  -c 'PDB$SEED CDB$ROOT' -U  "SYS"/"&&sysPassword"  -a 1   $ORACLE_HOME/ctx/admin/defaults/dr0defin.sql 1\"AMERICAN\";
host &&CATCON -b dbmsxdbt  -c 'PDB$SEED CDB$ROOT' -U  "SYS"/"&&sysPassword"         $ORACLE_HOME/rdbms/admin/dbmsxdbt.sql;

-- cwmlite 

SET VERIFY OFF
set echo on
connect "SYS"/"&&sysPassword" as SYSDBA

host &&CATCON -b  olap     -c 'PDB$SEED CDB$ROOT'  -U  "SYS"/"&&sysPassword"  -a 1 $ORACLE_HOME/olap/admin/olap.sql 1SYSAUX 1TEMP;

-- next: spatial 

SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on

host &&CATCON -b mdinst  -c 'PDB$SEED CDB$ROOT' -U  "SYS"/"&&sysPassword"          $ORACLE_HOME/md/admin/mdinst.sql;
spool off

-- next  ClusterDBViews

SET VERIFY OFF
connect "SYS"/"&&sysPassword" as SYSDBA
set echo on

host &&CATCON -b catclust                       -U  "SYS"/"&&sysPassword"          $ORACLE_HOME/rdbms/admin/catclust.sql;

host &&CATCON -b catfinal                       -U  "SYS"/"&&sysPassword"          $ORACLE_HOME/rdbms/admin/catfinal.sql;

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

alter session set container=pdb$seed;


-- next: Post DB creation

SET VERIFY OFF

-- Datapatch ?? 

host $ORACLE_HOME/OPatch/datapatch -skip_upgrade_check -db $ORACLE_SID;

connect "SYS"/"&&sysPassword" as SYSDBA

-- spfile: skip for now, I prefer doing this later manually
-- set echo on
-- create spfile='/opt/oracle/product/26ai/dbhome_1/dbs/spfilec2.ora' FROM pfile='/opt/oracle/admin/c2/scripts/init.ora';

connect "SYS"/"&&sysPassword" as SYSDBA

host &&CATCON -b utlrp   -U  "SYS"/"&&sysPassword"  $ORACLE_HOME/rdbms/admin/utlrp.sql;

select comp_id, status from dba_registry;

shutdown immediate;

connect "SYS"/"&&sysPassword" as SYSDBA

startup ;

-- why this ? 
select instance from v$thread where instance like 'UNNAMED_INSTANCE%';

prompt .
prompt  end of 3_crdb_components
prompt  consider adding some checks..
prompt . 

host echo End of 3_crdb_comp at `date` 

spool off

-- notes below

