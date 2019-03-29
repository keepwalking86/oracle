#Table of content

- [I. Enable ARCHIVELOG mode](#enable-archivelog)
- [II. Backup database](#backup)
  - [1. Full backup](#full-backup)
  - [2. Backup only tablespace](#backup-tablespace)
  - [3. Backup Archivelog](#backup-archivelog)
  - [4. Backup datafile](#backup-datafile)
  - [5. Backup Controlfile](#backup-controlfile)
  - [6. RMAN Incremental Backups](#backup-increase)
- [III. Restore-Recover database](#restore)
  - [1. 1. Restore when lost Datafile using RMAN](#restore-datafile)
  - [2. Restore when loss Control Files, Datafiles, and Redo Logs](#restore-all)
## <a name=""></a>

# <a name="enable-archivelo">I. Enable ARCHIVELOG mode</a>

**Step1**: Connect as a user with SYSDBA privileges.

`sqlplus / as sysdba`

**Step2**: Shut down the database instance using the NORMAL, IMMEDIATE, or TRANSACTIONAL option

`SQL>SHUTDOWN IMMEDIATE`

**Step3**: Start the instance and mount the database

`SQL>STARTUP MOUNT`

**Step4**: Place the database in ARCHIVELOG mode

`SQL>ALTER DATABASE ARCHIVELOG;`

**Step5**: Open the database

`SQL>ALTER DATABASE OPEN;`

**Step6**: Verify changes

`SQL>ARCHIVE LOG LIST`

>Database log mode	       Archive Mode
Automatic archival	       Enabled
Archive destination	       USE_DB_RECOVERY_FILE_DEST
Oldest online log sequence     17
Next log sequence to archive   19
Current log sequence	       19

**Step7**: Check log mode

```
SQL>select log_mode from v$database;
LOG_MODE
------------
ARCHIVELOG
```

**Step8**: Verify archived log location

```
SQL> show parameter db_recovery

NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
db_recovery_file_dest		     string	 /u01/flash_recovery_area
db_recovery_file_dest_size	     big integer 12780M
```

# <a name="backup">II. Backup database</a>

We take backup online using RMAN (database be running in ARCHIVELOG mode)

## <a name="full-backup">1. Backup full database</a>

Take full database backup give the following command

```
rman target /
RMAN>backup database
```
tag with other name

```
rman target /
RMAN>backup database tag 'OnlineFullBackup';
```

```
>Starting backup at 29-MAR-19
using target database control file instead of recovery catalog
allocated channel: ORA_DISK_1
channel ORA_DISK_1: SID=35 device type=DISK
channel ORA_DISK_1: starting full datafile backup set
channel ORA_DISK_1: specifying datafile(s) in backup set
input datafile file number=00001 name=/u01/app/oracle/oradata/ORCL/system01.dbf
input datafile file number=00003 name=/u01/app/oracle/oradata/ORCL/sysaux01.dbf
input datafile file number=00014 name=/u01/app/oracle/oradata/orcl/vnn01.dbf
input datafile file number=00004 name=/u01/app/oracle/oradata/ORCL/undotbs01.dbf
input datafile file number=00019 name=/u01/app/oracle/oradata/orcl/vnn02.dbf
input datafile file number=00020 name=/u01/app/oracle/oradata/orcl/vnn03.dbf
input datafile file number=00007 name=/u01/app/oracle/oradata/ORCL/users01.dbf
channel ORA_DISK_1: starting piece 1 at 29-MAR-19
channel ORA_DISK_1: finished piece 1 at 29-MAR-19
piece handle=/u01/flash_recovery_area/ORCL/backupset/2019_03_29/o1_mf_nnndf_ONLINEFULLBACKUP_g9v59mds_.bkp tag=ONLINEFULLBACKUP comment=NONE
channel ORA_DISK_1: backup set complete, elapsed time: 00:01:35
channel ORA_DISK_1: starting full datafile backup set
channel ORA_DISK_1: specifying datafile(s) in backup set
input datafile file number=00010 name=/u01/app/oracle/oradata/ORCL/PORCL/sysaux01.dbf
input datafile file number=00009 name=/u01/app/oracle/oradata/ORCL/PORCL/system01.dbf
input datafile file number=00011 name=/u01/app/oracle/oradata/ORCL/PORCL/undotbs01.dbf
input datafile file number=00012 name=/u01/app/oracle/oradata/ORCL/PORCL/users01.dbf
channel ORA_DISK_1: starting piece 1 at 29-MAR-19
channel ORA_DISK_1: finished piece 1 at 29-MAR-19
piece handle=/u01/flash_recovery_area/ORCL/850DA3869E29262EE0530F02000A6C89/backupset/2019_03_29/o1_mf_nnndf_ONLINEFULLBACKUP_g9v5dlqj_.bkp tag=ONLINEFULLBACKUP comment=NONE
channel ORA_DISK_1: backup set complete, elapsed time: 00:00:25
channel ORA_DISK_1: starting full datafile backup set
channel ORA_DISK_1: specifying datafile(s) in backup set
input datafile file number=00006 name=/u01/app/oracle/oradata/ORCL/pdbseed/sysaux01.dbf
input datafile file number=00005 name=/u01/app/oracle/oradata/ORCL/pdbseed/system01.dbf
input datafile file number=00008 name=/u01/app/oracle/oradata/ORCL/pdbseed/undotbs01.dbf
channel ORA_DISK_1: starting piece 1 at 29-MAR-19
channel ORA_DISK_1: finished piece 1 at 29-MAR-19
piece handle=/u01/flash_recovery_area/ORCL/850D969522241F9FE0530F02000A8C1F/backupset/2019_03_29/o1_mf_nnndf_ONLINEFULLBACKUP_g9v5fcrz_.bkp tag=ONLINEFULLBACKUP comment=NONE
channel ORA_DISK_1: backup set complete, elapsed time: 00:00:25
Finished backup at 29-MAR-19
Starting Control File and SPFILE Autobackup at 29-MAR-19
piece handle=/u01/flash_recovery_area/ORCL/autobackup/2019_03_29/o1_mf_s_1004179765_g9v5g5ld_.bkp comment=NONE
Finished Control File and SPFILE Autobackup at 29-MAR-19
RMAN>
```

## <a name="backup-tablespace">2. Backup only tablespace</a>

- Backup tablespace with name 'VNN'

```
rman target /
RMAN>backup tablespace VNN tag 'fullvnn';
```
```
Starting backup at 29-MAR-19
using target database control file instead of recovery catalog
allocated channel: ORA_DISK_1
channel ORA_DISK_1: SID=270 device type=DISK
channel ORA_DISK_1: starting full datafile backup set
channel ORA_DISK_1: specifying datafile(s) in backup set
input datafile file number=00014 name=/u01/app/oracle/oradata/orcl/vnn01.dbf
input datafile file number=00019 name=/u01/app/oracle/oradata/orcl/vnn02.dbf
input datafile file number=00020 name=/u01/app/oracle/oradata/orcl/vnn03.dbf
channel ORA_DISK_1: starting piece 1 at 29-MAR-19
channel ORA_DISK_1: finished piece 1 at 29-MAR-19
piece handle=/u01/flash_recovery_area/ORCL/backupset/2019_03_29/o1_mf_nnndf_FULLVNN_g9v3o8gd_.bkp tag=FULLVNN comment=NONE
channel ORA_DISK_1: backup set complete, elapsed time: 00:00:15
Finished backup at 29-MAR-19
Starting Control File and SPFILE Autobackup at 29-MAR-19
piece handle=/u01/flash_recovery_area/ORCL/autobackup/2019_03_29/o1_mf_s_1004177959_g9v3oqq9_.bkp comment=NONE
Finished Control File and SPFILE Autobackup at 29-MAR-19
```
- Show list backup

`RMAN> list backup;`

```
...
BS Key  Type LV Size       Device Type Elapsed Time Completion Time
------- ---- -- ---------- ----------- ------------ ---------------
24      Full    691.05M    DISK        00:00:01     29-MAR-19      
        BP Key: 24   Status: AVAILABLE  Compressed: NO  Tag: FULLVNN
        Piece Name: /u01/flash_recovery_area/ORCL/backupset/2019_03_29/o1_mf_nnndf_FULLVNN_g9v3o8gd_.bkp
  List of Datafiles in backup set 24
  File LV Type Ckp SCN    Ckp Time  Abs Fuz SCN Sparse Name
  ---- -- ---- ---------- --------- ----------- ------ ----
  14      Full 2178229    29-MAR-19              NO    /u01/app/oracle/oradata/orcl/vnn01.dbf
  19      Full 2178229    29-MAR-19              NO    /u01/app/oracle/oradata/orcl/vnn02.dbf
  20      Full 2178229    29-MAR-19              NO    /u01/app/oracle/oradata/orcl/vnn03.dbf
...
```

## <a name="backup-archivelog">3. Backup archive log files along with database</a>

Archived redo logs are the key to successful media recovery. Back them up regularly. You can back up logs with BACKUP ARCHIVELOG, or back up logs while backing up datafiles and control files by specifying BACKUP ... PLUS ARCHIVELOG.

**Backing Up Archived Redo Log Files with BACKUP ARCHIVELOG**

`RMAN>BACKUP ARCHIVELOG ALL;`

**Backing Up Logs with BACKUP ... PLUS ARCHIVELOG**

By backup with **plus archivelog**, then RMAN to do the following:

- Runs the ALTER SYSTEM ARCHIVE LOG CURRENT command.

- Runs BACKUP ARCHIVELOG ALL. Note that if backup optimization is enabled, then RMAN skips logs that it has already backed up to the specified device.

- Backs up the rest of the files specified in BACKUP command (as full backup, backup datafile, ...)

- Runs the ALTER SYSTEM ARCHIVE LOG CURRENT command.

- Backs up any remaining archived logs generated during the backup.

```
rman target /
RMAN> BACKUP DATABASE PLUS ARCHIVELOG;
```
## <a name="backup-datafile">4. Backup datafile</a>

With RMAN connected to the target database, use the BACKUP DATAFILE command to back up individual datafiles. We can specify the datafiles by name or number.

To use number, then show list

`SQL> SELECT FILE#,NAME FROM V$DATAFILE;`

Backup datafile 19,20, then:

`RMAN>BACKUP DATAFILE 19,20`

## <a name="backup-controlfile">5. Backup Controlfile using RMAN</a>

If `CONFIGURE CONTROLFILE AUTOBACKUP` is ON, then RMAN automatically backs up the control file and server parameter file after every backup and after database structural changes

If the autobackup feature is not set, then we manually back up the control file in one of the following ways:

```
rman target /
RMAN>BACKUP CURRENT CONTROLFILE;
```

## <a name="backup-increase">6. RMAN Incremental Backups</a>

Reference: [https://docs.oracle.com/cd/B19306_01/backup.102/b14192/bkup004.htm](https://docs.oracle.com/cd/B19306_01/backup.102/b14192/bkup004.htm)

# <a name="restore">III. Restore/recover using RMAN</a>

## <a name="restore-datafile">1. Restore when lost Datafile using RMAN</a>

- Remove /u01/app/oracle/oradata/orcl/vnn03.dbf

`rm -rf /u01/app/oracle/oradata/orcl/vnn03.dbf`

- Check database

```
SQL> shutdown immediate
ORA-01116: error in opening database file 20
ORA-01110: data file 20: '/u01/app/oracle/oradata/orcl/vnn03.dbf'
ORA-27041: unable to open file
Linux-x86_64 Error: 2: No such file or directory
Additional information: 3
```
- Restore loss datafile

Now type the following script at RMAN prompt to recover the loss datafile

**Option1**: Restore/recover from tablespace

```
sqlplus / as sysdba
SQL>shutdown abort;
SQL>startup mount;
RMAN TARGET /
RMAN>run {
          restore datafile '/u01/app/oracle/oradata/orcl/vnn03.dbf';
          recover datafile '/u01/app/oracle/oradata/orcl/vnn03.dbf';
          sql 'alter database open';
         }
```
**Option2**: Restore/recover from database full backup

```
sqlplus / as sysdba
SQL>shutdown abort;
SQL>startup mount;
RMAN TARGET /
RMAN> restore datafile 20; #from list backup;
```
## <a name="restore-all">2. Restore when loss Control Files, Datafiles, and Redo Logs</a>

**Step1**: Stop the database and start in the nomount stage

```
SQL>shutdown abort;
SQL>startup nomount;
```
**Step2**: Restore the control file from the backup

`RMAN> restore controlfile from autobackup;`

```
Starting restore at 29-MAR-19
using target database control file instead of recovery catalog
allocated channel: ORA_DISK_1
channel ORA_DISK_1: SID=21 device type=DISK

recovery area destination: /u01/flash_recovery_area
database name (or database unique name) used for search: ORCL
channel ORA_DISK_1: AUTOBACKUP /u01/flash_recovery_area/ORCL/autobackup/2019_03_29/o1_mf_s_1004181211_g9v6vd0q_.bkp found in the recovery area
AUTOBACKUP search with format "%F" not attempted because DBID was not set
channel ORA_DISK_1: restoring control file from AUTOBACKUP /u01/flash_recovery_area/ORCL/autobackup/2019_03_29/o1_mf_s_1004181211_g9v6vd0q_.bkp
channel ORA_DISK_1: control file restore from AUTOBACKUP complete
output file name=/u01/app/oracle/oradata/ORCL/control01.ctl
output file name=/u01/flash_recovery_area/ORCL/control02.ctl
Finished restore at 29-MAR-19
```

**Step3**: Brings the database to the mount stage

`SQL>alter database mount;`

**Step4**:  Restore the datafiles and recover the database

`RMAN> restore database;`

```
List of Cataloged Files
=======================
File Name: /u01/flash_recovery_area/ORCL/autobackup/2019_03_29/o1_mf_s_1004181211_g9v6vd0q_.bkp

using channel ORA_DISK_1

skipping datafile 5; already restored to file /u01/app/oracle/oradata/ORCL/pdbseed/system01.dbf
skipping datafile 6; already restored to file /u01/app/oracle/oradata/ORCL/pdbseed/sysaux01.dbf
skipping datafile 8; already restored to file /u01/app/oracle/oradata/ORCL/pdbseed/undotbs01.dbf
skipping datafile 9; already restored to file /u01/app/oracle/oradata/ORCL/PORCL/system01.dbf
skipping datafile 10; already restored to file /u01/app/oracle/oradata/ORCL/PORCL/sysaux01.dbf
skipping datafile 11; already restored to file /u01/app/oracle/oradata/ORCL/PORCL/undotbs01.dbf
skipping datafile 12; already restored to file /u01/app/oracle/oradata/ORCL/PORCL/users01.dbf
channel ORA_DISK_1: starting datafile backup set restore
channel ORA_DISK_1: specifying datafile(s) to restore from backup set
channel ORA_DISK_1: restoring datafile 00003 to /u01/app/oracle/oradata/ORCL/sysaux01.dbf
channel ORA_DISK_1: restoring datafile 00004 to /u01/app/oracle/oradata/ORCL/undotbs01.dbf
channel ORA_DISK_1: restoring datafile 00007 to /u01/app/oracle/oradata/ORCL/users01.dbf
channel ORA_DISK_1: reading from backup piece /u01/flash_recovery_area/ORCL/backupset/2019_03_29/o1_mf_nnndf_FULLBACKUP_g9tzp924_.bkp
channel ORA_DISK_1: piece handle=/u01/flash_recovery_area/ORCL/backupset/2019_03_29/o1_mf_nnndf_FULLBACKUP_g9tzp924_.bkp tag=FULLBACKUP
channel ORA_DISK_1: restored backup piece 1
channel ORA_DISK_1: restore complete, elapsed time: 00:00:45
channel ORA_DISK_1: starting datafile backup set restore
channel ORA_DISK_1: specifying datafile(s) to restore from backup set
channel ORA_DISK_1: restoring datafile 00014 to /u01/app/oracle/oradata/orcl/vnn01.dbf
channel ORA_DISK_1: restoring datafile 00019 to /u01/app/oracle/oradata/orcl/vnn02.dbf
channel ORA_DISK_1: restoring datafile 00020 to /u01/app/oracle/oradata/orcl/vnn03.dbf
channel ORA_DISK_1: reading from backup piece /u01/flash_recovery_area/ORCL/backupset/2019_03_29/o1_mf_nnndf_FULLVNN_g9v3o8gd_.bkp
channel ORA_DISK_1: piece handle=/u01/flash_recovery_area/ORCL/backupset/2019_03_29/o1_mf_nnndf_FULLVNN_g9v3o8gd_.bkp tag=FULLVNN
channel ORA_DISK_1: restored backup piece 1
channel ORA_DISK_1: restore complete, elapsed time: 00:00:25
channel ORA_DISK_1: starting datafile backup set restore
channel ORA_DISK_1: specifying datafile(s) to restore from backup set
channel ORA_DISK_1: restoring datafile 00001 to /u01/app/oracle/oradata/ORCL/system01.dbf
channel ORA_DISK_1: reading from backup piece /u01/flash_recovery_area/ORCL/backupset/2019_03_29/o1_mf_nnndf_TAG20190329T111255_g9v6t7j7_.bkp
channel ORA_DISK_1: piece handle=/u01/flash_recovery_area/ORCL/backupset/2019_03_29/o1_mf_nnndf_TAG20190329T111255_g9v6t7j7_.bkp tag=TAG20190329T111255
channel ORA_DISK_1: restored backup piece 1
channel ORA_DISK_1: restore complete, elapsed time: 00:00:35
Finished restore at 29-MAR-19
```

`RMAN> recover database;`

```
starting media recovery

archived log for thread 1 with sequence 11 is already on disk as file /u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_11_g9v0hdgn_.arc
archived log for thread 1 with sequence 12 is already on disk as file /u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_12_g9v0m284_.arc
archived log for thread 1 with sequence 13 is already on disk as file /u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_13_g9v2w69s_.arc
archived log for thread 1 with sequence 14 is already on disk as file /u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_14_g9v377cr_.arc
archived log for thread 1 with sequence 15 is already on disk as file /u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_15_g9v37khc_.arc
archived log for thread 1 with sequence 16 is already on disk as file /u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_16_g9v38r4l_.arc
archived log for thread 1 with sequence 17 is already on disk as file /u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_17_g9v39262_.arc
archived log for thread 1 with sequence 18 is already on disk as file /u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_18_g9v41ty7_.arc
archived log for thread 1 with sequence 19 is already on disk as file /u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_19_g9v6rh9y_.arc
archived log for thread 1 with sequence 20 is already on disk as file /u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_20_g9v6vbh1_.arc
archived log for thread 1 with sequence 21 is already on disk as file /u01/app/oracle/oradata/ORCL/redo03.log
archived log file name=/u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_11_g9v0hdgn_.arc thread=1 sequence=11
archived log file name=/u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_12_g9v0m284_.arc thread=1 sequence=12
archived log file name=/u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_13_g9v2w69s_.arc thread=1 sequence=13
archived log file name=/u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_14_g9v377cr_.arc thread=1 sequence=14
archived log file name=/u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_15_g9v37khc_.arc thread=1 sequence=15
archived log file name=/u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_16_g9v38r4l_.arc thread=1 sequence=16
archived log file name=/u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_17_g9v39262_.arc thread=1 sequence=17
archived log file name=/u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_18_g9v41ty7_.arc thread=1 sequence=18
archived log file name=/u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_19_g9v6rh9y_.arc thread=1 sequence=19
archived log file name=/u01/flash_recovery_area/ORCL/archivelog/2019_03_29/o1_mf_1_20_g9v6vbh1_.arc thread=1 sequence=20
archived log file name=/u01/app/oracle/oradata/ORCL/redo03.log thread=1 sequence=21
media recovery complete, elapsed time: 00:00:31
Finished recover at 29-MAR-19
```
**Step5**: Open the database with the resetlogs option

`SQL>alter database open resetlogs;`

**Note**: When has error for the same Sequence which was of the current log group. Oracle cannot find its archived file and the redo log is deleted. Therefore, whatever was inside it is lost and so this is an incomplete recovery. So opens the database with the resetlogs option and checks the number of the rows in the table.
So, Oracle recommends multiplexing the redo log files to different hard drives