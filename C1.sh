#!/bin/sh

# C1.sh - templat create script to call all others
#
# New ORACLE_SID is the name of the script.. 
# carry that name everywhere..
#
# todo:
# - SED-edit the init file and copy it to dbs
# 

ORACLE_SID="$(basename "$0")"
ORACLE_SID="${ORACLE_SID%.*}"
export ORACLE_SID

echo .
echo You are about to create a new container DB : $ORACLE_SID
echo .
echo Next: check the env-variables and the init.ora:
echo .
echo "ORACLE_BASE= " $ORACLE_BASE
echo "ORACLE_HOME= " $ORACLE_HOME
echo "ORACLE_SID=  " $ORACLE_SID
echo . 
ls -l init${ORACLE_SID}.ora
echo .
read -p "Control-C to cancel, if correct hit enter..." -t 10 abc
echo . 

#
# creating paths, code from generated script
#
OLD_UMASK=`umask`
umask 0027
mkdir -p /ompt/oracle
mkdir -p /opt/oracle/admin/${ORACLE_SID}/dpdump
mkdir -p /opt/oracle/admin/${ORACLE_SID}/pfile
mkdir -p /iopt/oracle/admin/${ORACLE_SID}/scripts
mkdir -p /opt/oracle/audit
mkdir -p /opt/oracle/oradata
mkdir -p /opt/oracle/product/26ai/dbhome_1/dbs
mkdir -p /opt/oracle/oradata/${ORACLE_SID}
umask ${OLD_UMASK}

cp init${ORACLE_SID}.ora ${ORACLE_HOME}/dbs/

# 
# perl- and path-settings came from generated script
#
PERL5LIB=$ORACLE_HOME/rdbms/admin:$PERL5LIB; export PERL5LIB
PATH=$ORACLE_HOME/bin:$ORACLE_HOME/perl/bin:$PATH; export PATH

echo You should Add this entry in the /etc/oratab: 
echo   $ORACLE_SID:/opt/oracle/product/26ai/dbhome_1:Y

# now go do the SQL..

/opt/oracle/product/26ai/dbhome_1/bin/sqlplus /nolog \
	@/opt/oracle/admin/$ORACLE_SID/scripts/0_crdb.sql

echo .
echo Call 2_crdb.sql, 3_ etc..
echo .
echo date and time `date` 
echo Done : $0
echo .
