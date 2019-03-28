#!/bin/bash
#Script to install Oracle database 12 on CentOS7
#Change HOSTNAME, IPs, SID & PATHs
#KeepWalking86 nguyenvodung@gmail.com

#Define variables
DOMAIN=example.local
HOSTNAME=db01
ORACLE_MOUNT=/u01
ORACLE_BASE=${ORACLE_MOUNT}/app/oracle
ORACLE_HOME=${ORACLE_BASE}/product/12.2.0.1/db_1
ORACLE_INVENTORY_LOCATION=/etc/oraInventory
ORACLE_SID=orcl
ORACLE_PORCL=porcl
SOURCEPATH=/home/setup
ORACLE_FILE=linuxx64_12201_database.zip
ORACLE_DIR=/home/oracle
ORACLE_PASSWORD=Oracle12c
IPADDRESS=192.168.1.118

#Check user account to run script
if [[ $UID -ne 0 ]]; then
        echo "You need root account to run script"
        exit 1;
fi

#Check oracle software
if [ ! -f ${SOURCEPATH}/${ORACLE_FILE} ]; then
	echo "${ORACLE_FILE} is not exist. You need to download ${ORACLE_FILE}"
	exit 1
fi

#Setting hostname
#echo "hostname=$HOSTNAME" >> /etc/sysconfig/network
#echo "$IPADDRESS $HOSTNAME" >>/etc/hosts
hostnamectl set-hostname $HOSTNAME --static

#Installing required packages
yum -y install binutils compat-libcap1 compat-libstdc++-33 glibc glibc-devel ksh libaio \
libaio-devel libX11 libXau libXi libXtst libgcc libstdc++ libstdc++-devel libxcb make \
nfs-utils smartmontools net-tools sysstat unzip


#groups for database management
echo "Creating groups for oracle database"
groupadd -g 54321 oinstall
groupadd -g 54322 dba
groupadd -g 54323 oper
groupadd -g 54324 backupdba
groupadd -g 54325 dgdba
groupadd -g 54326 kmdba
groupadd -g 54327 asmdba
groupadd -g 54328 asmoper
groupadd -g 54329 asmadmin
groupadd -g 54330 racdba

#Create oracle user
echo "Creating Oracle user"
useradd -u 54321 -g oinstall -G dba,oper,backupdba,dgdba,kmdba,racdba,oinstall oracle

echo "kernel parameters for 12gR2 installation"
cat >/etc/sysctl.conf <<EOF
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmni = 4096
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
fs.aio-max-nr = 1048576
net.ipv4.ip_local_port_range = 9000 65500
kernel.panic_on_oops=1
EOF
#Update parameters from file
/sbin/sysctl -p
sleep 5

echo "shell limits for users oracle 12gR2"
cat >>/etc/security/limits.conf <<EOF
oracle soft nofile 1024
oracle hard nofile 65536
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft stack 10240
oracle hard stack 32768
oracle soft memlock 3145728
oracle hard memlock 3145728
EOF

echo "Create directory structure"
mkdir -p $ORACLE_HOME
mkdir -p ${ORACLE_INVENTORY_LOCATION}
chmod -R 775 $ORACLE_MOUNT
chown -R oracle:oinstall $ORACLE_MOUNT
chown -R oracle:oinstall ${ORACLE_BASE}
chown -R oracle:oinstall ${ORACLE_INVENTORY_LOCATION}

echo "Setting Oracle environments"
mkdir $ORACLE_DIR/scripts
cat > $ORACLE_DIR/scripts/setEnv.sh <<EOF
# Oracle Settings
export TMP=/tmp
export TMPDIR=\$TMP
export ORACLE_HOSTNAME=$HOSTNAME
export ORACLE_UNQNAME=$ORACLE_SID
export ORACLE_BASE=$ORACLE_BASE
export ORACLE_HOME=$ORACLE_HOME
export ORACLE_SID=$ORACLE_SID
export PATH=/usr/sbin:/usr/local/bin:\$PATH
export PATH=\$ORACLE_HOME/bin:\$PATH
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib
EOF

echo ". ${ORACLE_DIR}/scripts/setEnv.sh" >> ${ORACLE_DIR}/.bash_profile

#Scrips for Oracle start/stop
##Start Oracle
cat > $ORACLE_DIR/scripts/start_all.sh <<EOF
#!/bin/bash
. ${ORACLE_DIR}/scripts/setEnv.sh
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES
dbstart \$ORACLE_HOME
EOF
##Stop Oracle
cat > ${ORACLE_DIR}/scripts/stop_all.sh <<EOF
#!/bin/bash
. ${ORACLE_DIR}/scripts/setEnv.sh
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES
dbshut \$ORACLE_HOME
EOF

chown -R oracle.oinstall ${ORACLE_DIR}/scripts
chmod u+x ${ORACLE_DIR}/scripts/*.sh

#Prepare ORACLE database software for installation
cp ${SOURCEPATH}/${ORACLE_FILE} $ORACLE_DIR
cd ${ORACLE_DIR}
unzip ${ORACLE_FILE}
chown -R oracle:oinstall ${ORACLE_DIR}/database

#Response files
cat >$ORACLE_DIR/database/db_install.rsp <<EOF
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v12.2.0
oracle.install.option=INSTALL_DB_SWONLY
UNIX_GROUP_NAME=oinstall
INVENTORY_LOCATION=${ORACLE_INVENTORY_LOCATION}
ORACLE_HOME=${ORACLE_HOME}
ORACLE_BASE=${ORACLE_BASE}
oracle.install.db.InstallEdition=EE
oracle.install.db.OSDBA_GROUP=dba
oracle.install.db.OSOPER_GROUP=oper
oracle.install.db.OSBACKUPDBA_GROUP=backupdba
oracle.install.db.OSDGDBA_GROUP=dgdba
oracle.install.db.OSKMDBA_GROUP=kmdba
oracle.install.db.OSRACDBA_GROUP=racdba
oracle.install.db.isRACOneInstall=false
oracle.install.db.rac.serverpoolCardinality=0
oracle.install.db.config.starterdb.type=GENERAL_PURPOSE
oracle.install.db.ConfigureAsContainerDB=false
oracle.install.db.config.starterdb.memoryOption=false
oracle.install.db.config.starterdb.installExampleSchemas=false
oracle.install.db.config.starterdb.managementOption=DEFAULT
SECURITY_UPDATES_VIA_MYORACLESUPPORT=false
DECLINE_SECURITY_UPDATES=true
EOF

echo "----------------------------------------"
echo "Starting Oracle binaries installation"
echo "----------------------------------------"
sleep 5
su oracle -c "cd $ORACLE_DIR/database; ./runInstaller -silent -showProgress -waitForCompletion -responseFile $ORACLE_DIR/database/db_install.rsp"

#${ORACLE_INVENTORY_LOCATION}/orainstRoot.sh
echo "Configure DB software"
${ORACLE_HOME}/root.sh

###Config Oracle net
echo "---------------------------------------------------"
echo "-----------Configuring Oracle Net------------------"
echo "---------------------------------------------------"
echo "Configure LISTENER with standard settings"
cat >${ORACLE_DIR}/database/netca.rsp<<EOF
[GENERAL]
RESPONSEFILE_VERSION="12.2"
CREATE_TYPE="CUSTOM"
SHOW_GUI=false
[oracle.net.ca]
INSTALLED_COMPONENTS={"server","net8","javavm"}
INSTALL_TYPE=""typical""
LISTENER_NUMBER=1
LISTENER_NAMES={"LISTENER"}
LISTENER_PROTOCOLS={"TCP;1521"}
LISTENER_START=""LISTENER""
NAMING_METHODS={"TNSNAMES","ONAMES","HOSTNAME"}
NSN_NUMBER=1
NSN_NAMES={"EXTPROC_CONNECTION_DATA"}
NSN_SERVICE={"PLSExtProc"}
NSN_PROTOCOLS={"TCP;HOSTNAME;1521"}
EOF
su oracle -c "${ORACLE_HOME}/bin/netca -silent -responseFile ${ORACLE_DIR}/database/netca.rsp"
su oracle -c "${ORACLE_HOME}/bin/lsnrctl start"

###Configure database
#create new container database ORCL.example.local with one pluggable database PORCL 
#Make directories datafiles and flash recovery area
echo "---------------------------------------------------"
echo "-----------Configuring Oracle Database-------------"
echo "---------------------------------------------------"

echo "Make directories for database datafiles and flash recovery area"
mkdir $ORACLE_BASE/oradata
mkdir $ORACLE_MOUNT/flash_recovery_area
chown -R oracle:oinstall $ORACLE_BASE/oradata
chown -R oracle:oinstall $ORACLE_MOUNT/flash_recovery_area
sleep 3

#Make response file for dbca;
cd ${ORACLE_DIR}/database
cat >dbca.rsp <<EOF
gdbName=$ORACLE_SID
sid=$ORACLE_SID
createAsContainerDatabase=true
numberOfPDBs=1
pdbName=${ORACLE_PORCL}
pdbAdminPassword=${ORACLE_PASSWORD}
templateName=General_Purpose.dbc
sysPassword=${ORACLE_PASSWORD}
systemPassword=${ORACLE_PASSWORD}
emConfiguration=DBEXPRESS
emExpressPort=5500
dbsnmpPassword=${ORACLE_PASSWORD}
datafileDestination=${ORACLE_BASE}/oradata
recoveryAreaDestination=${ORACLE_MOUNT}/flash_recovery_area
storageType=FS
characterSet=AL32UTF8
nationalCharacterSet=AL16UTF16
listeners=LISTENER
sampleSchema=true
databaseType=OLTP
automaticMemoryManagement=FALSE
totalMemory=2048
EOF

#Checking listener
echo "Checking LISTENER"
if netstat -nta |grep -i listen |grep 1521 >/dev/null; then
        echo "LISTERNER is running, port 1521"
else
        su oracle -c "$ORACLE_HOME/bin/lsnrctl start"
fi

#Oracle Instance
echo "Creating and starting Oracle instance"
su oracle -c "${ORACLE_HOME}/bin/dbca -silent -createDatabase -responseFile $ORACLE_DIR/database/dbca.rsp"

#dbstart utility bring up at system boot time"
echo "Bring up at system boot time"
sed -i '/^$ORACLE_SID/c\$ORACLE_SID:$ORACLE_HOME:Y' /etc/oratab

#Finish Scripting
