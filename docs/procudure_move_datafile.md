# Move old datafile location to new datafile location on both primary and standby servers

**On standby database**

```
SQL> shutdown immediate
SQL> startup mount
SQL> select name from v$datafile;
NAME
--------------------------------------------------------------------------------
/u01/app/oracle/oradata/sorcl/sorcl/system01.dbf
/u01/app/oracle/oradata/sorcl/sorcl/sysaux01.dbf
/u01/app/oracle/oradata/sorcl/sorcl/undotbs01.dbf
/u01/app/oracle/oradata/sorcl/sorcl/users01.dbf
/u02/oradata/smsgw01.dbf

SQL> alter databse recover managed standby database cancel;
SQL> alter system set standby_file_management=manual;
SQL> !mv /u02/oradata/smsgw01.dbf /u01/app/oracle/oradata/sorcl/sorcl/
SQL> alter database rename file '/u02/oradata/smsgw01.dbf' to '/u01/app/oracle/oradata/sorcl/sorcl/smsgw01.dbf';
Database altered.
SQL> alter system set standby_file_management=auto;
SQL> alter database recover managed standby database disconnect from session;
Database altered.
```

**On primary database**

```
SQL> shutdown immediate
Database closed.
Database dismounted.
ORACLE instance shut down.
SQL> !mv /u02/oradata/smsgw01.dbf /u01/app/oracle/oradata/orcl/orcl
SQL> startup mount
SQL> alter database rename file '/u02/oradata/smsgw01.dbf' to '/u01/app/oracle/oradata/orcl/orcl/smsgw01.dbf';
Database altered.
SQL> alter database open;
Database altered.
SQL> select name from v$datafile;
NAME
--------------------------------------------------------------------------------
/u01/app/oracle/oradata/orcl/orcl/system01.dbf
/u01/app/oracle/oradata/orcl/orcl/sysaux01.dbf
/u01/app/oracle/oradata/orcl/orcl/undotbs01.dbf
/u01/app/oracle/oradata/orcl/orcl/users01.dbf
/u01/app/oracle/oradata/orcl/orcl/smsgw01.dbf
```

**Check state of both databases by dgmgrl**

```
DGMGRL> show configuration
Configuration - orcl_dgmgrl
  Protection Mode: MaxAvailability
  Databases:
    orcl  - Primary database
    sorcl - Physical standby database
Fast-Start Failover: DISABLED
Configuration Status:
SUCCESS
DGMGRL>
```
