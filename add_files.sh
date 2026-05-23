#!/bin/bash
#
# add_files.sh : add redo, threads, and datafiles to check ctlfile_records
# add items to check limits of controlfile
# and watch controlfile expand from messages in alert-log
#

LOGFILE=log_add_redo.log

sqlplus / as sysdba <<EOF | tee $LOGFILE
  prompt .
  prompt First, list the values in ctlfile-records
  prompt .
  @chk_ctlrecords
EOF

for NR in {1..12}
do
sqlplus / as sysdba <<EOF | tee -a $LOGFILE
  alter database add logfile size 50M ; 
EOF

done

# show effect
sqlplus / as sysdba <<EOF | tee -a $LOGFILE
  prompt .
  prompt Added some redo-files..
  prompt Show the increase of redo, despite the max-value
  prompt .
  @chk_ctlrecords
  prompt .
  prompt Next: add some datafiles, and check result
  prompt .
EOF

# add tablespaces to get over 30 tblspaces and 30 datafiles
for NR in {1..30}
do
sqlplus / as sysdba <<EOF | tee -a $LOGFILE
  create tablespace TS${NR} datafile size 10M ;
EOF
done

# add more logfiles, and threads
for GRP in {1..10}
do
sqlplus / as sysdba <<EOF | tee -a $LOGFILE
  alter database add logfile thread 1 size 50M ; 
  alter database add logfile thread 2 size 50M ; 
  alter database add logfile thread 3 size 50M ; 
EOF
done

# show result of datafiles and threads..
sqlplus / as sysdba <<EOF | tee -a $LOGFILE
  prompt .
  prompt Added datafiles and redo-threads..
  prompt re-check contents of controlfile
  prompt .
  @chk_ctlrecords
  prompt .
EOF

