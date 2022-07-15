# Step by Step to configure Oracle 19c Data Guard Active-Standby

Primary: 172.16.0.10
Secondary: 172.16.0.11

## 1. Primary Server side Configurations

**Step1: Change Archivelog mode and force logging mode**

```
[oracle@oracle01 ~]$ export ORACLE_SID=oracle01
[oracle@oracle01 ~]$ sqlplus / as sysdba
SQL*Plus: Release 19.0.0.0.0 - Production on Fri Oct 18 12:19:23 2019
Version 19.3.1.0.0
Copyright (c) 1982, 2019, Oracle. All rights reserved.
Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.1.0.0
```

```
SQL> startup mount
ORACLE instance started.
Total System Global Area 1048575776 bytes
Fixed Size 8904480 bytes
Variable Size 272629760 bytes
Database Buffers 763363328 bytes
Redo Buffers 3678208 bytes
Database mounted.
```

- Enable archivelog, flashback

```
SQL> alter database archivelog;
Database altered.

SQL> alter database flashback on;
Database altered.

SQL> ALTER DATABASE FORCE LOGGING;
Database altered.

SQL> alter database open;
Database altered.

SQL> select log_mode, flashback_on, force_logging from v$database;

LOG_MODE     FLASHBACK_ON	FORCE_LOGGING
------------ ------------------ ---------------------------------------
ARCHIVELOG   YES		YES

SQL> 
```

**Step2:Adding Redolog file for standby database**

```
SQL>alter database add standby logfile thread 1 group 4 ('/data/oradata/ORACLE01/standby_redo01.log') size 200m;
SQL>alter database add standby logfile thread 1 group 5 ('/data/oradata/ORACLE01/standby_redo02.log') size 200m;
SQL>alter database add standby logfile thread 1 group 6 ('/data/oradata/ORACLE01/standby_redo03.log') size 200m;
```

Check standby log files

```
SQL> SELECT GROUP#,THREAD#,SEQUENCE#,ARCHIVED,STATUS FROM V$STANDBY_LOG;

GROUP# THREAD# SEQUENCE# ARC STATUS
4 0 0 YES UNASSIGNED
5 0 0 YES UNASSIGNED
6 0 0 YES UNASSIGNED
```

**Step3: Adding the network entry in primary and standby side(Both servers)**

**On Primary**

- Update tnsname

vi /u01/app/oracle/product/19.3.0/db_1/network/admin/tnsnames.ora

```
ORACLE01 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.0.10)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = oracle01)
    )
  )

LISTENER_ORACLE01 =
  (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.0.10)(PORT = 1521))

ORACLE02 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.0.11)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = oracle02)
    )
  )
```

- Update listener

`vi /u01/app/oracle/product/19.3.0/db_1/network/admin/listener.ora`

```
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.0.10)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )

SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = oracle01)
      (ORACLE_HOME = /u01/app/oracle/product/19.3.0/db_1)
      (SID_NAME = oracle01)
    )
  )
```
**On Standby**

- Update tnsname

```
LISTENER_ORACLE02 =
  (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.0.11)(PORT = 1521))
ORACLE01 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.0.10)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = oracle01)
    )
  )

ORACLE02 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.0.11) (PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = oracle02)
    )
  )
ODS =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.0.11)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ODS)
    )
  )
```

- Update listener

```
#/u01/app/oracle/product/19.3.0/db_1/network/admin/listener.ora
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.0.11)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = oracle02)
      (ORACLE_HOME = /u01/app/oracle/product/19.3.0/db_1)
      (SID_NAME = oracle02)
    )
  )
```

- Reload 

`lsnrctl reload`

- Check ping

```
[oracle@oracle01 ~]$ tnsping oracle01

TNS Ping Utility for Linux: Version 19.0.0.0.0 - Production on 25-JUN-2022 10:30:01

Copyright (c) 1997, 2019, Oracle.  All rights reserved.

Used parameter files:
/u01/app/oracle/product/19.3.0/db_1/network/admin/sqlnet.ora


Used TNSNAMES adapter to resolve the alias
Attempting to contact (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = oracle01)(PORT = 1521)) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = oracle01)))
OK (0 msec)

[oracle@oracle01 ~]$ tnsping oracle02

TNS Ping Utility for Linux: Version 19.0.0.0.0 - Production on 25-JUN-2022 10:30:03

Copyright (c) 1997, 2019, Oracle.  All rights reserved.

Used parameter files:
/u01/app/oracle/product/19.3.0/db_1/network/admin/sqlnet.ora


Used TNSNAMES adapter to resolve the alias
Attempting to contact (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = oracle02)(PORT = 1521)) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = oracle02)))
OK (0 msec)
```

**step4: Changing parameters in primary database**

```
SQL> ALTER SYSTEM SET log_archive_config='dg_config=(oracle01,oracle02)' SCOPE=both;
System altered.

SQL> ALTER SYSTEM SET log_archive_dest_1='location=use_db_recovery_file_dest valid_for=(all_logfiles,all_roles) db_unique_name=oracle01' SCOPE=both;
System altered.

SQL> ALTER SYSTEM SET log_archive_dest_2='service=oracle02 async valid_for=(online_logfiles,primary_role) db_unique_name=oracle02' SCOPE=both;
System altered.

SQL> ALTER SYSTEM SET fal_server='oracle02' SCOPE=both;
System altered.

SQL> ALTER SYSTEM SET fal_client='oracle01' SCOPE=both;
System altered.

SQL> ALTER SYSTEM SET standby_file_management='AUTO' SCOPE=both;
System altered.
```

- Can dump spfile to pfile for checking

```
SQL>select value from v$parameter where name = 'spfile';

SQL>create pfile='/u01/app/oracle/product/19.3.0/db_1/dbs/pfileoracle01.ora' from spfile;
```

## 2. Standby Server side Configurations

**Step5: Password file creation**

Copy the remote login password file (orapworacle01) from the primary database server to the $ORACLE_HOME/dbs directory on the
standby database server, renaming it to orapworacle02.

```
cd $ORACLE_HOME/dbs
[oracle@oracle02 dbs]$ mv orapworacle01 orapworacle02
```

**Step6: Changing parameters in standby database**

In the `$ORACLE_HOME/dbs` directory of the standby system, create an initialization parameter file named initoracle02.ora
Containing a single parameter: DB_NAME=oracle01

`[oracle@oracle02 dbs]$ cat /u01/app/oracle/product/19.3.0/db_1/dbs/initoracle02.ora`

```
*.audit_file_dest='/u01/app/oracle/admin/oracle02/adump'
*.audit_trail='db'
*.compatible='19.0.0'
*.control_files='/data/oradata/ORACLE02/control01.ctl','/u01/flash_recovery_area/ORACLE02/control02.ctl'
*.db_block_size=8192
*.db_name='oracle01'
*.DB_UNIQUE_NAME=oracle02
*.db_recovery_file_dest='/u01/flash_recovery_area'
*.db_recovery_file_dest_size=12732m
*.diagnostic_dest='/u01/app/oracle'
*.dispatchers='(PROTOCOL=TCP) (SERVICE=oracle02XDB)'
*.enable_pluggable_database=true
*.fal_client='oracle02'
*.fal_server='oracle01'
*.local_listener='LISTENER_ORACLE02'
*.log_archive_config='dg_config=(oracle01,oracle02)'
*.log_archive_dest_1='location=use_db_recovery_file_dest valid_for=(all_logfiles,all_roles) db_unique_name=oracle02'
*.log_archive_dest_2='service=oracle01 async valid_for=(online_logfiles,primary_role) db_unique_name=oracle01'
*.nls_language='AMERICAN'
*.nls_territory='AMERICA'
*.open_cursors=300
*.pga_aggregate_target=768m
*.processes=320
*.remote_login_passwordfile='EXCLUSIVE'
*.sga_target=2304m
*.standby_file_management='AUTO'
*.undo_tablespace='UNDOTBS1'
```

**Step7: Create directory Structure in Standby database**

```
cd $ORACLE_BASE/admin/
mkdir -p oracle02/adump
mkdir -p /data/oradata/ORACLE02
```

**Step8: start the standby database using pfile**

```
cd $ORACLE_HOME/dbs
[oracle@oracle02 dbs]$ export ORACLE_SID=oracle02

[oracle@oracle02 dbs]$ lsnrctl stop

[oracle@oracle02 dbs]$ lsnrctl start

[oracle@oracle02 dbs]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Sat Jun 25 11:54:43 2022
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.

Connected to an idle instance.
```

```
SQL> startup pfile='/u01/app/oracle/product/19.3.0/db_1/dbs/initoracle02.ora' nomount
ORACLE instance started.

Total System Global Area  306183456 bytes
Fixed Size		    8895776 bytes
Variable Size		  239075328 bytes
Database Buffers	   50331648 bytes
Redo Buffers		    7880704 bytes
```

**Step9: Create duplicate.rman**

vi duplicate.rman

```
run {
allocate channel p1 type disk;
allocate channel p2 type disk;
allocate channel p3 type disk;
allocate channel p4 type disk;
allocate auxiliary channel s1 type disk;
duplicate target database for standby from active database
spfile
parameter_value_convert 'oracle01','oracle02'
set db_name='oracle01'
set db_unique_name='oracle02'
set db_file_name_convert='/data/oradata/ORACLE01/','/data/oradata/ORACLE02/'
set log_file_name_convert='/u01/flash_recovery_area/ORACLE01/onlinelog/','/u01/flash_recovery_area/ORACLE02/onlinelog/','/data/oradata/ORACLE01/','/data/oradata/ORACLE02/'
set control_files='/data/oradata/ORACLE02/control01.ctl','/u01/flash_recovery_area/ORACLE02/control02.ctl'
set log_archive_max_processes='10'
set fal_client='oracle02'
set fal_server='oracle01'
set log_archive_config='dg_config=(oracle01,oracle02)'
set log_archive_dest_1='location=/u01/flash_recovery_area/ORACLE02/archivelog valid_for=(all_logfiles,all_roles) db_unique_name=oracle02'
set log_archive_dest_2='service=oracle01 ASYNC valid_for=(ONLINE_LOGFILE,PRIMARY_ROLE) db_unique_name=oracle01'
set standby_file_management='AUTO'
nofilenamecheck
;
}
```

**Step10: Create directories that contain PDBs(Pluggable Database)**

If PDSs have created on the primary, then need to create directories structure on the standby

```
[oracle@oracle02 dbs]$ mkdir /data/oradata/ORACLE02/pdbseed
[oracle@oracle02 dbs]$ mkdir /data/oradata/ORACLE02/ODS
[oracle@oracle02 dbs]$ chmod 750 /data/oradata/ORACLE02/pdbseed/
[oracle@oracle02 dbs]$ chmod 750 /data/oradata/ORACLE02/ODS/
```

**Step11: Connect to the rman**

```
cd $ORACLE_HOME/dbs
rman target sys/Oracle19c@oracle01 auxiliary sys/Oracle19c@oracle02

SQL> startup nomount pfile='/u01/app/oracle/product/19.3.0/db_1/dbs/initoracle02.ora';
ORACLE instance started.

Total System Global Area 2415918608 bytes
Fixed Size		    9137680 bytes
Variable Size		  520093696 bytes
Database Buffers	 1879048192 bytes
Redo Buffers		    7639040 bytes
SQL> exit
Disconnected from Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0
[oracle@oracle02 dbs]$ rman TARGET sys/Oracle19c@oracle01 AUXILIARY sys/Oracle19c@oracle02

Recovery Manager: Release 19.0.0.0.0 - Production on Mon Jun 27 02:00:30 2022
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

connected to target database: ORACLE01 (DBID=2702048740)
connected to auxiliary database: ORACLE01 (not mounted)

RMAN> 
```

```
RMAN>@duplicate.rman

...
executing Memory Script

datafile 1 switched to datafile copy
input datafile copy RECID=5 STAMP=1108461549 file name=/data/oradata/ORACLE02/system01.dbf
datafile 3 switched to datafile copy
input datafile copy RECID=6 STAMP=1108461549 file name=/data/oradata/ORACLE02/sysaux01.dbf
datafile 4 switched to datafile copy
input datafile copy RECID=7 STAMP=1108461549 file name=/data/oradata/ORACLE02/undotbs01.dbf
datafile 5 switched to datafile copy
input datafile copy RECID=8 STAMP=1108461549 file name=/data/oradata/ORACLE02/pdbseed/system01.dbf
datafile 6 switched to datafile copy
input datafile copy RECID=9 STAMP=1108461549 file name=/data/oradata/ORACLE02/pdbseed/sysaux01.dbf
datafile 7 switched to datafile copy
input datafile copy RECID=10 STAMP=1108461549 file name=/data/oradata/ORACLE02/users01.dbf
datafile 8 switched to datafile copy
input datafile copy RECID=11 STAMP=1108461549 file name=/data/oradata/ORACLE02/pdbseed/undotbs01.dbf
datafile 9 switched to datafile copy
input datafile copy RECID=12 STAMP=1108461549 file name=/data/oradata/ORACLE02/ODS/system01.dbf
datafile 10 switched to datafile copy
input datafile copy RECID=13 STAMP=1108461549 file name=/data/oradata/ORACLE02/ODS/sysaux01.dbf
datafile 11 switched to datafile copy
input datafile copy RECID=14 STAMP=1108461549 file name=/data/oradata/ORACLE02/ODS/undotbs01.dbf
datafile 12 switched to datafile copy
input datafile copy RECID=15 STAMP=1108461549 file name=/data/oradata/ORACLE02/ODS/users01.dbf
Finished Duplicate Db at 27-JUN-22
released channel: p1
released channel: p2
released channel: p3
released channel: p4
released channel: s1

RMAN> **end-of-file**
```

**Step12: Checking synchronize correctly on standby**

- Checking archive log files

```
[oracle@oracle02 dbs]$ sqlplus / as sysdba

SQL> !ls /u01/flash_recovery_area/ORACLE02/archivelog
1_8_1108422182.dbf

SQL> alter database recover managed standby database disconnect from session;

Database altered.

SQL> select name, applied from v$archived_log;

NAME
--------------------------------------------------------------------------------
APPLIED
---------
/u01/flash_recovery_area/ORACLE02/archivelog/1_8_1108422182.dbf
NO

`SQL> SELECT sequence#, first_time, next_time, applied FROM v$archived_log ORDER BY sequence#;`

 SEQUENCE# FIRST_TIM NEXT_TIME APPLIED
---------- --------- --------- ---------
	 8 26-JUN-22 27-JUN-22 YES

SQL> 
```

- Check the difference

```
SQL> SELECT ARCH.THREAD# "Thread", ARCH.SEQUENCE# "Last Sequence Received", APPL.SEQUENCE# "Last Sequence Applied", (ARCH.SEQUENCE# - APPL.SEQUENCE#) "Difference" FROM (SELECT THREAD# ,SEQUENCE# FROM V$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH,(SELECT THREAD# ,SEQUENCE# FROM V$LOG_HISTORY WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL WHERE ARCH.THREAD# = APPL.THREAD# ORDER BY 1;

    Thread Last Sequence Received Last Sequence Applied Difference
---------- ---------------------- --------------------- ----------
	 1			8		      8 	 0

SQL> 
```

- Check database

```
SQL> select name from v$database;

NAME
---------
ORACLE01

SQL> show pdbs;

    CON_ID CON_NAME			  OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
	 2 PDB$SEED			  MOUNTED
	 3 ODS				  MOUNTED
SQL> 
```