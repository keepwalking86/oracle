# Change NOARCHIVELOG mode to the Database Archiving Mode

**Step1**: Invoke SQL*Plus and connect as a user with SYSDBA privileges.

`sqlplus / as sysdba`

**Step2**: Shut down the database instance using the NORMAL, IMMEDIATE, or TRANSACTIONAL option

`SQL>SHUTDOWN IMMEDIATE`

**Step3**: Make a whole database backup including all data files and control files.

You can use operating system commands or RMAN to perform this operation.
This backup can be used in the future for recovery with archived redo log files that will be created once the database is in ARCHIVELOG mode.

**Step4**: Start the instance and mount the database

`SQL>STARTUP MOUNT`

**Step5**: Place the database in ARCHIVELOG mode

`SQL>ALTER DATABASE ARCHIVELOG;`

**Step6**: Open the database

`SQL>ALTER DATABASE OPEN;`

**Step7**: Verify your changes

`SQL>ARCHIVE LOG LIST`

**Step8**: Check log mode

`SQL>select log_mode from v$database;`

**Step9**: Verify archived log location

`SQL> show parameter db_recovery
