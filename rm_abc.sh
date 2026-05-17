
# adhoc script for cleanup

export ORACLE_SID=C004
export ORACLE_SID_LOWER=${ORACLE_SID,,}

set echo on

rm -v $ORACLE_HOME/dbs/init$ORACLE_SID.*

rm -v $ORACLE_HOME/dbs/init$ORACLE_SID.*
rm -v $ORACLE_HOME/dbs/spfile$ORACLE_SID.*
rm -v $ORACLE_HOME/dbs/orapw$ORACLE_SID
rm -v $ORACLE_HOME/dbs/hc_$ORACLE_SID*.dat
rm -v $ORACLE_HOME/dbs/lk$ORACLE_SID*

# more radical removal..
# rm -v $ORACLE_HOME/dbs/*${ORACLE_SID}*

rm -v $ORACLE_BASE/admin/$ORACLE_SID/xdb_wallet/*.*
rm -v $ORACLE_BASE/admin/$ORACLE_SID/adump/*.*
rm -v $ORACLE_BASE/admin/$ORACLE_SID/bdump/*.*
rm -v $ORACLE_BASE/admin/$ORACLE_SID/udump/*.*

# not removing the scripts dir
# rm -v $ORACLE_BASE/admin/$ORACLE_SID/scripts/*.*

# set -v -x 
rm -rf $ORACLE_BASE/diag/rdbms/${ORACLE_SID_LOWER}

# any remaining datafiles
rm -rf $ORACLE_BASE/oradata/$ORACLE_SID/*

set echo off

