#!/bin/ksh
#
# mk_rmall.sh: generate rm-script and shutdown-abort the current SID
#
# output: do_rmall.lst 
#
# for safety: output script must be run explicitly as prompt> sh do_rmall.lst
#
# todo: 
# - put whole script inside single sh, eliminate dependency on sql-file
# - some files have lowercase-SID in name: fix! 
# 
#

SPOOLFILE=do_rm_${ORACLE_SID}

sqlplus /nolog <<EOF | tee log_rm_${ORACLE_SID}.log

-- avoid un-wanted prompt in spoolfile, put a comment-hash as prompt.
set sqlprompt '# ' 

connect / as sysdba

-- use for CRDB only, too risky to use elsewhere..
-- note: using separate SQL-file to avoid prompt in stdout, find workaround

set echo     off
set heading  off
set feedb    off
set linesize 192
set trimspool on

spool ${SPOOLFILE}
@mk_rmall
spool off

shutdown abort 

EOF

echo .
echo database instance ${ORACLE_SID} is shut down,
echo you can use spoolfile ${SPOOLFILE} to remove files
echo .

