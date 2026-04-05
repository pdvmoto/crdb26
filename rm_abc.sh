
# adhoc script for cleanup

export ORACLE_SID=C1
export ORACLE_SID_LOWER=${ORACLE_SID,,}

set echo on

rm $ORACLE_HOME/dbs/init$ORACLE_SID.*

rm $ORACLE_HOME/dbs/spfile$ORACLE_SID.*
rm $ORACLE_HOME/dbs/orapw$ORACLE_SID.*
rm $ORACLE_HOME/dbs/hc_$ORACLE_SID*.dat
rm $ORACLE_HOME/dbs/lk$ORACLE_SID*

rm $ORACLE_BASE/admin/$ORACLE_SID/xdb_wallet/*.*

set -v -x 
rm -rf $ORACLE_BASE/diag/rdbms/${ORACLE_SID_LOWER}

rm -rf $ORACLE_BASE/oradata/$ORACLE_SID

set echo off

