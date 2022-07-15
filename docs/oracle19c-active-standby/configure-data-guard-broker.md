# Configure Data Guard Broker

## 1. Enable broker

**Step1: Configure Dataguard Broker on both servers**

- On Primary server

```
SQL> ALTER SYSTEM SET dg_broker_start=true scope=both;

System altered.

SQL> alter system set log_archive_dest_2='' scope=both;

System altered.

SQL> ALTER SYSTEM SET local_listener='(DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.0.10)(PORT = 1521))) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = oracle01)))' scope=both;
System altered.

SQL> 
```

- On Standby server

```
SQL> ALTER SYSTEM SET dg_broker_start=true scope=both;

System altered.

SQL> alter system set log_archive_dest_2='' scope=both;

System altered.

SQL> ALTER SYSTEM SET local_listener='(DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.0.11)(PORT = 1521))) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = oracle02)))' scope=both;

System altered.
```

- Show broker configuration

```
SQL> sho parameter broker

NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
connection_brokers		     string	 ((TYPE=DEDICATED)(BROKERS=1)),
						  ((TYPE=EMON)(BROKERS=1))
dg_broker_config_file1		     string	 /u01/app/oracle/product/19.3.0
						 /db_1/dbs/dr1oracle01.dat
dg_broker_config_file2		     string	 /u01/app/oracle/product/19.3.0
						 /db_1/dbs/dr2oracle01.dat
dg_broker_start 		     boolean	 TRUE
use_dedicated_broker		     boolean	 FALSE
SQL> 
```

**Step2:- Enable Dataguard Broker**

- On Primary server

```
dgmgrl sys/Oracle19c@oracle01
DGMGRL> create configuration oracle01_conf as primary database is oracle01 connect identifier is oracle01;

DGMGRL> add database oracle02 as connect identifier is oracle02 maintained as physical;
Database "oracle02" added
DGMGRL> enable configuration
DGMGRL> show configuration

Configuration - oracle01_conf

  Protection Mode: MaxPerformance
  Members:
  oracle01 - Primary database
    oracle02 - Physical standby database 

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 3 seconds ago)

DGMGRL>

DGMGRL> show configuration verbose;

Configuration - oracle01_conf

  Protection Mode: MaxPerformance
  Members:
  oracle01 - Primary database
    oracle02 - Physical standby database 

  Properties:
    FastStartFailoverThreshold      = '30'
    OperationTimeout                = '30'
    TraceLevel                      = 'USER'
    FastStartFailoverLagLimit       = '30'
    CommunicationTimeout            = '180'
    ObserverReconnect               = '0'
    FastStartFailoverAutoReinstate  = 'TRUE'
    FastStartFailoverPmyShutdown    = 'TRUE'
    BystandersFollowRoleChange      = 'ALL'
    ObserverOverride                = 'FALSE'
    ExternalDestination1            = ''
    ExternalDestination2            = ''
    PrimaryLostWriteAction          = 'CONTINUE'
    ConfigurationWideServiceName    = 'oracle01_CFG'

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS
```
```
DGMGRL> show database oracle01

Database - oracle01

  Role:               PRIMARY
  Intended State:     TRANSPORT-ON
  Instance(s):
    oracle01

Database Status:
SUCCESS

DGMGRL> show database oracle02

Database - oracle02

  Role:               PHYSICAL STANDBY
  Intended State:     APPLY-ON
  Transport Lag:      0 seconds (computed 1 second ago)
  Apply Lag:          0 seconds (computed 1 second ago)
  Average Apply Rate: 5.00 KByte/s
  Real Time Query:    OFF
  Instance(s):
    oracle02

Database Status:
SUCCESS

DGMGRL> 
```

**Step3: Update listener.ora Network Configuration File on both servers**

- On Primary

```
#vi /u01/app/oracle/product/19.3.0/db_1/network/admin/listener.ora
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
      (GLOBAL_DBNAME = oracle01_DGMGRL)
      (ORACLE_HOME = /u01/app/oracle/product/19.3.0/db_1)
      (SID_NAME = oracle01)
    )
  )
```

Reload listener and check

```
[oracle@oracle01 ~]$ lsnrctl stat

LSNRCTL for Linux: Version 19.0.0.0.0 - Production on 14-JUL-2022 18:07:32

Copyright (c) 1991, 2019, Oracle.  All rights reserved.

Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=172.16.0.10)(PORT=1521)))
STATUS of the LISTENER
------------------------
Alias                     LISTENER
Version                   TNSLSNR for Linux: Version 19.0.0.0.0 - Production
Start Date                08-JUL-2022 11:46:50
Uptime                    6 days 6 hr. 20 min. 42 sec
Trace Level               off
Security                  ON: Local OS Authentication
SNMP                      OFF
Listener Parameter File   /u01/app/oracle/product/19.3.0/db_1/network/admin/listener.ora
Listener Log File         /u01/app/oracle/diag/tnslsnr/oracle01/listener/alert/log.xml
Listening Endpoints Summary...
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=172.16.0.10)(PORT=1521)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1521)))
Services Summary...
Service "86b637b62fdf7a65e053f706e80a27ca" has 1 instance(s).
  Instance "oracle01", status READY, has 1 handler(s) for this service...
Service "e21b503f9fef3c8be0550a0027c12e19" has 1 instance(s).
  Instance "oracle01", status READY, has 1 handler(s) for this service...
Service "e29ad2374c18779ae0530a0010ac8f29" has 1 instance(s).
  Instance "oracle01", status READY, has 1 handler(s) for this service...
Service "ods" has 1 instance(s).
  Instance "oracle01", status READY, has 1 handler(s) for this service...
Service "ods2" has 1 instance(s).
  Instance "oracle01", status READY, has 1 handler(s) for this service...
Service "oracle01" has 1 instance(s).
  Instance "oracle01", status READY, has 1 handler(s) for this service...
Service "oracle01XDB" has 1 instance(s).
  Instance "oracle01", status READY, has 1 handler(s) for this service...
Service "oracle01_CFG" has 1 instance(s).
  Instance "oracle01", status READY, has 1 handler(s) for this service...
Service "oracle01_DGMGRL" has 1 instance(s).
  Instance "oracle01", status UNKNOWN, has 1 handler(s) for this service...
Service "pdb2" has 1 instance(s).
  Instance "oracle01", status READY, has 1 handler(s) for this service...
The command completed successfully
```

- On Standby

```
#vi /u01/app/oracle/product/19.3.0/db_1/network/admin/listener.ora
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 172.16.0.9)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = oracle02_DGMGRL)
      (ORACLE_HOME = /u01/app/oracle/product/19.3.0/db_1)
      (SID_NAME = oracle02)
    )
  )
```

Reload and check

```
[oracle@oracle02 dbs]$ lsnrctl stat

LSNRCTL for Linux: Version 19.0.0.0.0 - Production on 14-JUL-2022 18:08:58

Copyright (c) 1991, 2019, Oracle.  All rights reserved.

Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=172.16.0.9)(PORT=1521)))
STATUS of the LISTENER
------------------------
Alias                     LISTENER
Version                   TNSLSNR for Linux: Version 19.0.0.0.0 - Production
Start Date                13-JUL-2022 17:20:27
Uptime                    1 days 0 hr. 48 min. 30 sec
Trace Level               off
Security                  ON: Local OS Authentication
SNMP                      OFF
Listener Parameter File   /u01/app/oracle/product/19.3.0/db_1/network/admin/listener.ora
Listener Log File         /u01/app/oracle/diag/tnslsnr/oracle02/listener/alert/log.xml
Listening Endpoints Summary...
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=172.16.0.9)(PORT=1521)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1521)))
Services Summary...
Service "ods" has 1 instance(s).
  Instance "oracle02", status READY, has 1 handler(s) for this service...
Service "ods2" has 1 instance(s).
  Instance "oracle02", status READY, has 1 handler(s) for this service...
Service "oracle01_CFG" has 1 instance(s).
  Instance "oracle02", status READY, has 1 handler(s) for this service...
Service "oracle02" has 2 instance(s).
  Instance "oracle01", status BLOCKED, has 1 handler(s) for this service...
  Instance "oracle02", status READY, has 1 handler(s) for this service...
Service "oracle02XDB" has 1 instance(s).
  Instance "oracle02", status READY, has 1 handler(s) for this service...
Service "oracle02_DGMGRL" has 1 instance(s).
  Instance "oracle02", status UNKNOWN, has 1 handler(s) for this service...
Service "pdb2" has 1 instance(s).
  Instance "oracle02", status READY, has 1 handler(s) for this service...
The command completed successfully
```

## 2. Database Switchover

- Check validate

```
DGMGRL> VALIDATE DATABASE oracle01

  Database Role:    Primary database

  Ready for Switchover:  Yes

  Managed by Clusterware:
    oracle01:  NO             
    Validating static connect identifier for the primary database oracle01...
    The static connect identifier allows for a connection to database "oracle01".

DGMGRL>
DGMGRL> VALIDATE DATABASE oracle02

  Database Role:     Physical standby database
  Primary Database:  oracle01

  Ready for Switchover:  Yes
  Ready for Failover:    Yes (Primary Running)

  Managed by Clusterware:
    oracle01:  NO             
    oracle02:  NO             
    Validating static connect identifier for the primary database oracle01...
    The static connect identifier allows for a connection to database "oracle01".

  Current Log File Groups Configuration:
    Thread #  Online Redo Log Groups  Standby Redo Log Groups Status       
              (oracle01)              (oracle02)                           
    1         3                       3                       Insufficient SRLs

  Future Log File Groups Configuration:
    Thread #  Online Redo Log Groups  Standby Redo Log Groups Status       
              (oracle02)              (oracle01)                           
    1         3                       3                       Insufficient SRLs
```

- Switchover

```
DGMGRL> switchover to oracle02
Performing switchover NOW, please wait...
Operation requires a connection to database "oracle02"
Connecting ...
Connected to "oracle02"
Connected as SYSDBA.
New primary database "oracle02" is opening...
Operation requires start up of instance "oracle01" on database "oracle01"
Starting instance "oracle01"...
Connected to an idle instance.
ORACLE instance started.
Connected to "oracle01"
Database mounted.
Database opened.
Connected to "oracle01"
Switchover succeeded, new primary is "oracle02"
DGMGRL> 
```

- Checking roles

```
DGMGRL> show configuration

Configuration - oracle01

  Protection Mode: MaxPerformance
  Members:
  oracle02 - Primary database
    oracle01 - Physical standby database 

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 32 seconds ago)

DGMGRL> 
```

## 3. Database Failover

Failover is used when primary is not available, and then convert standby into primary database.

**On Standby**

- Check log

`tailf ../trace/alert_oracle01.log`

```
2022-07-15T11:04:59.505564+07:00
 rfs (PID:132151): Possible network disconnect with primary database
2022-07-15T11:04:59.509989+07:00
 rfs (PID:132145): Possible network disconnect with primary database
2022-07-15T11:04:59.756932+07:00
 rfs (PID:132149): Possible network disconnect with primary database
2022-07-15T11:05:00.251976+07:00
 rfs (PID:132147): Possible network disconnect with primary database
```

- Check the database role and mode

```
SQL> select name,open_mode,database_role from v$database;

NAME	  OPEN_MODE	       DATABASE_ROLE
--------- -------------------- ----------------
ORACLE01  READ ONLY WITH APPLY PHYSICAL STANDBY
```

- Cancel the MRP process

```
SQL> recover managed standby database cancel;
Media recovery complete.
SQL> 
```
- Bring up standby as primary

```
SQL> alter database recover managed standby database finish;

Database altered.

SQL> 
```

- Recheck the database role and mode

```
SQL> select name,open_mode,database_role from v$database;

NAME	  OPEN_MODE	       DATABASE_ROLE
--------- -------------------- ----------------
ORACLE01  READ ONLY	       PHYSICAL STANDBY
```

- Convert Standby to Primary Database

```
SQL>alter database activate standby database;

Database altered.

SQL> select name,open_mode,database_role from v$database;

NAME	  OPEN_MODE	       DATABASE_ROLE
--------- -------------------- ----------------
ORACLE01  MOUNTED	       PRIMARY
```

MRP has been stopped between primary and standby database and standby becomes primary database.

- Reopen database mode

```
SQL> 
shutdown immediate;

Database closed.
Database dismounted.
ORACLE instance shut down.
SQL> SQL> startup
ORA-32004: obsolete or deprecated parameter(s) specified for RDBMS instance
ORACLE instance started.

Total System Global Area 2415918568 bytes
Fixed Size		    9137640 bytes
Variable Size		  536870912 bytes
Database Buffers	 1862270976 bytes
Redo Buffers		    7639040 bytes
Database mounted.
Database opened.
SQL> 

SQL> select name,open_mode,database_role from v$database;

NAME	  OPEN_MODE	       DATABASE_ROLE
--------- -------------------- ----------------
ORACLE01  READ WRITE	       PRIMARY
```
