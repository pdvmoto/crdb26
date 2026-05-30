
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

DEFINE CATCTL="$ORACLE_HOME/perl/bin/perl $ORACLE_HOME/rdbms/admin/catctl.pl -n 2 -l /tmp "
DEFINE CATCON="$ORACLE_HOME/perl/bin/perl $ORACLE_HOME/rdbms/admin/catcon.pl -n 2 -l /tmp -v "

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
prompt  end of components from Files and Catalog, 
prompt  consider adding some checks..
prompt . 

spool off

