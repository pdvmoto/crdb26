
-- 2_crdb : contains the db-files and db-catalog parts 
-- 
-- todo/questions
-- 	- why the ";"  behind the script ? 
-- 	- why does catctlpl takes n=4, and catcon takes n=1
-- 	- can we write to ALERT already in between steps
--	- can we leave out the -d option at catctl.pl ? 
-- 

spool log_2_crdb_catalog.log append

@accpwds 


-- from CreatDBFiles.sql: add a dflt-USER tablespace to CDB -- 

SET VERIFY OFF

connect "SYS"/"&&sysPassword" as SYSDBA

set echo on

CREATE BIGFILE TABLESPACE "USERS" LOGGING  
	DATAFILE  SIZE 20M AUTOEXTEND ON NEXT  10M MAXSIZE UNLIMITED  
	EXTENT MANAGEMENT LOCAL  SEGMENT SPACE MANAGEMENT  AUTO;

ALTER DATABASE DEFAULT TABLESPACE "USERS";

-- from CreateDBCatalog: some scripts: -- 
--   catctl + catcon, doing catpcat, owminst, pubbld, pubdel, helpbld: 


-- start with some Defines to shorten the commands, define RCTL and RCON
-- notice how -l sends lofiles to /tmp
-- notice how catctl does not have a -v

DEFINE CATCTL="$ORACLE_HOME/perl/bin/perl $ORACLE_HOME/rdbms/admin/catctl.pl -n 1 -l /tmp "
DEFINE CATCON="$ORACLE_HOME/perl/bin/perl $ORACLE_HOME/rdbms/admin/catcon.pl -n 1 -l /tmp -v "


-- these prep-stmnts were in generated script:
alter session set "_oracle_script"=true;
alter pluggable database pdb$seed close;
alter pluggable database pdb$seed open;

-- in the generatd script, the last file didnt have $OH in front of it ?
host &&CATCTL -u "SYS"/"&&sysPassword" -icatpcat -c 'CDB$ROOT PDB$SEED' -a  -d $ORACLE_HOME/rdbms/admin rdbms/admin/catpcat.sql;


host &&CATCON -b owminst  -U  "SYS"/"&&sysPassword"  $ORACLE_HOME/rdbms/admin/owminst.plb;

host &&CATCON -b pupbld   -u  SYSTEM/&&systemPassword   -U  "SYS"/"&&sysPassword"  $ORACLE_HOME/sqlplus/admin/pupbld.sql;

host &&CATCON -b pupdel   -u  SYS/&&sysPassword         -U  "SYS"/"&&sysPassword"  $ORACLE_HOME/sqlplus/admin/pupdel.sql;

-- the generated script did a reconnect..

connect "SYS"/"&&sysPassword" as SYSDBA

set echo on

host &&CATCON -b hlpbld   -u  SYS/&&sysPassword         -U  "SYS"/"&&sysPassword"  -a 1   $ORACLE_HOME/sqlplus/admin/help/hlpbld.sql;

prompt .
prompt  end of components from Files and Catalog, 
prompt  consider adding some checks..
prompt . 

spool off

