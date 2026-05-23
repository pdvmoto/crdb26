#!/bin/ksh
#
# mk_rmall.sh: generate rm-script and shutdown-abort the current SID
#
# output: do_rmall.lst 
#
# for safety: output script must be run explicitly as prompt> sh do_rmall.lst
#

sqlplus /nolog <<EOF | tee log_rm_${ORACLE_SID}.log

connect / as sysdba

-- use for CRDB only, too risky to use elsewhere..

set echo     off
set heading  off
set feedb    off
set linesize 192
set trimspool on

spool do_rm_${ORACLE_SID}
@mk_rmall
host echo #
host echo rm $ORACLE_HOME/dbs/init${ORACLE_SID}.ora
host echo rm $ORACLE_HOME/dbs/spfile${ORACLE_SID}.ora
host echo rm $ORACLE_HOME/dbs/orapw${ORACLE_SID}
spool off

shutdown abort 

EOF

echo .
echo database instance ${ORACLE_SID} is shut down,
echo you can use spoolfile do_rm_${ORACLE_SID}.lst to remove files.
echo .

