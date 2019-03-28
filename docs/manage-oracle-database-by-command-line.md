#########Manage Oracle Database by command line (Basic)###########

# Table of contens

- [I. Managing Database](#managing-database)
  - [1. Add/Modify/Drop](#alter)
  - [2. Show information](#show-information)
- [II. Managing user](#managing-user)
  - [1. Creating common user](#common-user)
  - [2. Creating local user](#local-user)
  - [3. Setup Users permissions, roles](#user-permission)
- [III. Connect to database](#connect-database)

# <a name="managing-database">I. Managing Database</a>

## <a name="alter">1. Add/Modify/Drop</a>

- Create tablespace with the first datafile

SQL> create tablespace mytables datafile '/u01/app/oracle/oradata/orcl/mytables01.dbf' size 100m;

Tablespace created.

- Tạo tablespace with autoextend

SQL> create tablespace vnn datafile '/u01/app/oracle/oradata/orcl/vnn01.dbf' size 50m autoextend on next 5m maxsize 500m;

- Add second datafile

sql>alter tablespace mytables add datafile '/u01/app/oracle/oradata/orcl/mytables02.dbf' size 100m;

- drop a datafile

sql>alter tablespace mytables drop datafile '/u01/app/oracle/oradata/orcl/mytables02.dbf';

**Note**: cannot drop the first file of tablespace

- Change datafile size

**option1**: extend tablespace by increase a datafile size

```
sql>alter database datafile '/u01/app/oracle/oradata/orcl/mytables01.dbf' resize 500m;
OR:
sql>alter database orcl datafile '/u01/app/oracle/oradata/orcl/mytables01.dbf' resize 500m;
```

**option2**: extend tablespace by adding a new datafile

`sql>alter tablespace add datafile '/u01/app/oracle/oradata/orcl/mytables03.dbf' size 100m;`

**option3**: autoextend datafile

`SQL> alter database datafile '/u01/app/oracle/oradata/orcl/mytables03.dbf' autoextend on next 5m maxsize 500m;`

- Change tablespace readonly

sql>alter tablespace mytables read only;

- Change tablespace to read write

`sql>alter tablespace mytables read write;`

- logging tablespace

`sql>alter tablespace mytables force logging;`

- no log tablespace

`sql>alter tablespace mytables nologging;`

- Rename tablespace

Rename mytable to yourtable

`sql>alter tablespace mytables rename to yourtables;`

- Drop tablespace include: contents and datafiles

`sql>drop tablespace yourtables including contents and datafiles;`


## 2. Show information

$sqlplus /as sysdba

- show database

```
SQL> select name from v$database;

NAME
---------
ORCL
```
- show tablespace

```
SQL> select * from v$tablespace;

       TS# NAME 			  INC BIG FLA ENC     CON_ID
---------- ------------------------------ --- --- --- --- ----------
	 1 SYSAUX			  YES NO  YES		   1
	 0 SYSTEM			  YES NO  YES		   1
	 2 UNDOTBS1			  YES NO  YES		   1
	 4 USERS			  YES NO  YES		   1
	 3 TEMP 			  NO  NO  YES		   1
	 0 SYSTEM			  YES NO  YES		   2
	 1 SYSAUX			  YES NO  YES		   2
	 2 UNDOTBS1			  YES NO  YES		   2
	 3 TEMP 			  NO  NO  YES		   2
	 0 SYSTEM			  YES NO  YES		   3
	 1 SYSAUX			  YES NO  YES		   3

       TS# NAME 			  INC BIG FLA ENC     CON_ID
---------- ------------------------------ --- --- --- --- ----------
	 2 UNDOTBS1			  YES NO  YES		   3
	 3 TEMP 			  NO  NO  YES		   3
	 5 USERS			  YES NO  YES		   3

14 rows selected.
```
```
SQL> select name from v$tablespace;

NAME
------------------------------
SYSAUX
SYSTEM
UNDOTBS1
USERS
TEMP
SYSTEM
SYSAUX
UNDOTBS1
TEMP
SYSTEM
SYSAUX

NAME
------------------------------
UNDOTBS1
TEMP
USERS

14 rows selected.

```

**show tablespace with order number (ex: display ts# & name field)**

`sql>select ts#,name from v$tablespace;`

- show datafile

```
SQL> select name from v$datafile;

NAME
--------------------------------------------------------------------------------
/u01/app/oracle/oradata/ORCL/system01.dbf
/u01/app/oracle/oradata/ORCL/sysaux01.dbf
/u01/app/oracle/oradata/ORCL/undotbs01.dbf
/u01/app/oracle/oradata/ORCL/pdbseed/system01.dbf
/u01/app/oracle/oradata/ORCL/pdbseed/sysaux01.dbf
/u01/app/oracle/oradata/ORCL/users01.dbf
/u01/app/oracle/oradata/ORCL/pdbseed/undotbs01.dbf
/u01/app/oracle/oradata/ORCL/PORCL/system01.dbf
/u01/app/oracle/oradata/ORCL/PORCL/sysaux01.dbf
/u01/app/oracle/oradata/ORCL/PORCL/undotbs01.dbf
/u01/app/oracle/oradata/ORCL/PORCL/users01.dbf

11 rows selected.
```

**show  datafile with order number**

`sql>select ts#,name from v$datafile;`

- show controlfile

```
sql>select name from v$controlfile;

NAME
--------------------------------------------------------------------------------
/u01/app/oracle/oradata/ORCL/control01.ctl
/u01/flash_recovery_area/ORCL/control02.ctl
```

- show logfile

```
SQL> select member from v$logfile;

MEMBER
--------------------------------------------------------------------------------
/u01/app/oracle/oradata/ORCL/redo03.log
/u01/app/oracle/oradata/ORCL/redo02.log
/u01/app/oracle/oradata/ORCL/redo01.log
```

- show tables from a tablespace

```
SQL> select table_name from all_tables where (tablespace_name='SMSGW');

TABLE_NAME
--------------------------------------------------------------------------------
CHARGE_QUEUE
EMS_SEND_QUEUE
MO_REBUILD_QUEUE
PROVIDER_SEND_QUEUE
BLACK_LIST
TC_USER
CDR_SEQUENCE
CODE_LIST
CHARGE_QUEUE_REBUILD
NEIF

10 rows selected.
```

- list all tables owned by the current user

`sql>select tablespace_name, table_name from user_tables; `

- list all tables in a database

`sql>select tablespace_name, table_name from dba_tables;`

- list all tables accessible to the current user

`sql>select tablespace_name, table_name from all_tables;`

- show properties dba_tablespaces

`sql>desc dba_tablespaces;`

- show status

`sql>select tablespace_name,status from dba_tablespaces;`

- show size datafile

`sql>select name,bytes/1024/1024 from v$datafile;`

- Show tablespace free space(GB)

`select tablespace_name,sum(bytes)/1024/1024/1024 "Free space (GB)" from dba_free_space group by tablespace_name;`

- Show datafiles on a tablespace

`select file_name,blocks,tablespace_name from dba_data_files where tablespace='MYTABLES';`

# <a name="managing-user">II. Managing User</a>

Reference: [https://docs.oracle.com/database/121/SQLRF/statements_8003.htm#SQLRF01503](https://docs.oracle.com/database/121/SQLRF/statements_8003.htm#SQLRF01503)

We can create 2 types of users in Multitenant databases

	1. Common User
	2. Local User

- Common User:- A common user is created in root CDB. Common user can connect to root CDB and all PDB’s including future PDB’s which you may plug. 

We should not create any objects in Common User account as it will cause problems while connecting and disconnecting PDBs

- Local User:- A local user is created in a PDB database and can connect and has privileges in that PDB only.

## <a name="common-user">1. Creating a common user account</a>

```
SQL> create user c##admin identified by adminpwd container=all;
SQL> grant connect,resource to c##admin;
SQL> conn c##admin/adminpwd
```

**Note**: To create 12c user without c## prefix then solution is to set a hidden parameter "_oracle_script".

```
SQL> alter session set "_ORACLE_SCRIPT"=true;

Session altered.

SQL> create user keepwalking86 identified by Passw0rd;

User created.

SQL> grant dba to keepwalking86;

Grant succeeded.

SQL> connect keepwalking86/Passw0rd
Connected.
SQL> 
```

## <a name="local-user">2. Creating a Local User</a>

```
SQL> alter session set container=porcl;
SQL> create user dungnv identified by Passw0rd quota 50M on users;
SQL> grant connect,resource to dungnv;
```

## <a name="user-permission">3. Setup Users permissions, roles</a>

- show all users;

`sql>select username from dba_users;`

- create users

`sql>create user dungnv identified by Passw0rd;`

- grant session permis

`sql>grant create session, resource to dungnv`

- Try to login with dungnv account

`sql>conn dungnv/Passw0rd`

- set quota to user

```
$sqlplus / as sysdba
sql>select name from v$tablespace;
sql>alter user dungnv quota 10m on mytables;
sqll>alter user dungnv quota unlimited on mytables;
```

- Can set temp 

`sql>alter user dungnv temporary tablespace temp;`

- Set default tablespace for user

`sql>alter user dungnv default tablespace users;`

- change password

`sql>alter user dungnv identified by Oracle12c`

# <a name="connect-database">III. Connect to database</a>

## Connect through EZConnect

`SQL> conn keepwalking86/Passw0rd@192.168.10.244/orcl`

## Connect TNSNames

To connect through TNSNames you have to add entry in the TNSNames.ora file.

Open TNSNames.ora file add the following entry

```
cd $ORACLE_HOME/network/admin

cat >tnsnames.ora<<EOF
LISTENER_ORCL =
  (ADDRESS = (PROTOCOL = TCP)(HOST = db01)(PORT = 1521))


ORCL =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = db01)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ORCL)
    )
  )
EOF
```

Now to connect

`sqlplus keepwalking86/P@ssw0rd@orcl`
