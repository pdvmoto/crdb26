#!/bin/bash

# create some 25 tablespaces..

THEPDB=C002P002

for TSITER in {1..45}
do
  echo tablespace $ITER

  sqlplus /nolog<<EOF 

  conn / as sysdba 

  alter session set container = $THEPDB

  @pr6

  create tablespace zz_ts${TSITER} datafile size 5M ; 

EOF

done

