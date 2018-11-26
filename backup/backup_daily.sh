#!/bin/bash
#Script for daily backup
ORACLE_PASSWORD=Oracle12c
#Set Environment Variables
export ORACLE_BASE=/u01/app/oracle;
export ORACLE_SID=orcl
export ORACLE_HOME=${ORACLE_BASE}/product/12.2.0.1/db_1;
export PATH=$PATH:$ORACLE_HOME/bin
rman target sys@orcl/"$ORACLE_PASSWORD" cmdfile=/u01/oracle/backupset/backup_daily.rcv log=/u01/oracle/backupset/log/backup_daily_$(date +"%Y-%m-%d-%H-%M-%S").log
exit
