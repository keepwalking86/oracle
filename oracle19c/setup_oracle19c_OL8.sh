#!/bin/bash
#Script to install Oracle database 19c on Oracle Linux 8
#Change HOSTNAME, IPs, SID & PATHs
#KeepWalking86

#Define variables
DOMAIN=dwh.local
HOSTNAME=dwh
ORACLE_MOUNT=/u01
ORACLE_BASE=${ORACLE_MOUNT}/app/oracle
ORACLE_HOME=${ORACLE_BASE}/product/19.3.0/db_1
ORACLE_INVENTORY_LOCATION=/u01/app/oraInventory
ORACLE_SID=dwh
ORACLE_PORCL=ODS
SOURCEPATH=/home/setup
ORACLE_FILE=LINUX.X64_193000_db_home.zip
ORACLE_DIR=/home/oracle
DATA_DIR=/data/oradata
ORACLE_PASSWORD=Oracle19c
IPADDRESS=172.16.0.11

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
dnf install -y oracle-database-preinstall-19c
dnf update -y
dnf install bc binutils glibc libXrender libXrender-devel glibc-devel ksh libaio libaio-devel \
libX11 libXau libXi libXtst libgcc libstdc++ libstdc++-devel libxcb make nfs-utils smartmontools net-tools sysstat unzip \
elfutils-libelf elfutils-libelf-devel fontconfig-devel libnsl libnsl.i686 libnsl2 libnsl2.i686 libstdc++ libstdc++-devel -y

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

echo "kernel parameters for oracle 19c installation"
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

echo "shell limits for users oracle 19c"
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
[[ ! -d $ORACLE_HOME ]] && mkdir -p $ORACLE_HOME
[[ ! -d $ORACLE_INVENTORY_LOCATION ]] && mkdir -p ${ORACLE_INVENTORY_LOCATION}
chmod -R 775 $ORACLE_MOUNT
chown -R oracle:oinstall $ORACLE_MOUNT
chown -R oracle:oinstall ${ORACLE_BASE}
chown -R oracle:oinstall ${ORACLE_INVENTORY_LOCATION}

echo "Setting Oracle environments"
[[ ! -d $ORACLE_HOME/scripts ]] && mkdir $ORACLE_HOME/scripts
cat > $ORACLE_HOME/scripts/setEnv.sh <<EOF
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
export CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib:\$ORACLE_HOME/network/jlib
EOF

echo ". ${ORACLE_HOME}/scripts/setEnv.sh" >> ${ORACLE_DIR}/.bash_profile

#Scrips for Oracle start/stop
##Start Oracle
cat > $ORACLE_HOME/scripts/start_all.sh <<EOF
#!/bin/bash
. ${ORACLE_HOME}/scripts/setEnv.sh
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES
dbstart \$ORACLE_HOME
EOF
##Stop Oracle
cat > ${ORACLE_HOME}/scripts/stop_all.sh <<EOF
#!/bin/bash
. ${ORACLE_HOME}/scripts/setEnv.sh
export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES
dbshut \$ORACLE_HOME
EOF

chown -R oracle.oinstall ${ORACLE_HOME}/scripts
chmod u+x ${ORACLE_HOME}/scripts/*.sh

#Prepare ORACLE database software for installation
cp ${SOURCEPATH}/${ORACLE_FILE} $ORACLE_DIR && cd $ORACLE_DIR
unzip ${ORACLE_FILE} -d ${ORACLE_HOME}
#mkdir -p ${ORACLE_DIR}/database && chown -R oracle:oinstall ${ORACLE_DIR}
chown -R oracle:oinstall ${ORACLE_HOME}

#Response files
cat >$ORACLE_HOME/db_install.rsp <<EOF
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v19.0.0
oracle.install.option=INSTALL_DB_SWONLY
UNIX_GROUP_NAME=oinstall
INVENTORY_LOCATION=${ORACLE_INVENTORY_LOCATION}
ORACLE_HOME=${ORACLE_HOME}
ORACLE_BASE=${ORACLE_BASE}
oracle.install.db.InstallEdition=EE
oracle.install.db.OSDBA_GROUP=dba
oracle.install.db.OSOPER_GROUP=oper
oracle.install.db.OSBACKUPDBA_GROUP=dba
oracle.install.db.OSDGDBA_GROUP=dba
oracle.install.db.OSKMDBA_GROUP=dba
oracle.install.db.OSRACDBA_GROUP=dba
oracle.install.db.rootconfig.executeRootScript=false
oracle.install.db.rootconfig.configMethod=
oracle.install.db.rootconfig.sudoPath=
oracle.install.db.rootconfig.sudoUserName=
oracle.install.db.CLUSTER_NODES=
oracle.install.db.config.starterdb.type=GENERAL_PURPOSE
oracle.install.db.config.starterdb.globalDBName=
oracle.install.db.config.starterdb.SID=
oracle.install.db.ConfigureAsContainerDB=false
oracle.install.db.config.PDBName=
oracle.install.db.config.starterdb.characterSet=AL32UTF8
oracle.install.db.config.starterdb.memoryOption=true
oracle.install.db.config.starterdb.memoryLimit=
oracle.install.db.config.starterdb.installExampleSchemas=false
oracle.install.db.config.starterdb.password.ALL=
oracle.install.db.config.starterdb.password.SYS=
oracle.install.db.config.starterdb.password.SYSTEM=
oracle.install.db.config.starterdb.password.DBSNMP=
oracle.install.db.config.starterdb.password.PDBADMIN=
oracle.install.db.config.starterdb.managementOption=DEFAULT
oracle.install.db.config.starterdb.omsHost=
oracle.install.db.config.starterdb.omsPort=0
oracle.install.db.config.starterdb.emAdminUser=
oracle.install.db.config.starterdb.emAdminPassword=
oracle.install.db.config.starterdb.enableRecovery=false
oracle.install.db.config.starterdb.storageType=
oracle.install.db.config.starterdb.fileSystemStorage.dataLocation=
oracle.install.db.config.starterdb.fileSystemStorage.recoveryLocation=
oracle.install.db.config.asm.diskGroup=
oracle.install.db.config.asm.ASMSNMPPassword=
EOF

echo "----------------------------------------"
echo "Starting Oracle binaries installation"
echo "----------------------------------------"
sleep 5
su oracle -c "export CV_ASSUME_DISTID=OEL8.6;$ORACLE_HOME/runInstaller -silent -debug -waitForCompletion -responseFile $ORACLE_HOME/db_install.rsp"

#Setup and configure DB software
#${ORACLE_INVENTORY_LOCATION}/orainstRoot.sh
#${ORACLE_HOME}/root.sh
/u01/app/oraInventory/orainstRoot.sh
/u01/app/oracle/product/19.3.0/db_1/root.sh

###Config Oracle net
echo "---------------------------------------------------"
echo "-----------Configuring Oracle Net------------------"
echo "---------------------------------------------------"
echo "Configure LISTENER with standard settings"
cat >${ORACLE_HOME}/netca.rsp<<EOF
[GENERAL]
RESPONSEFILE_VERSION="19.3.0"
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
su oracle -c "${ORACLE_HOME}/bin/netca -silent -responseFile ${ORACLE_HOME}/netca.rsp"
su oracle -c "${ORACLE_HOME}/bin/lsnrctl start"

###Configure database
#create new container database ORCL.example.local with one pluggable database PORCL
#Make directories datafiles and flash recovery area
echo "---------------------------------------------------"
echo "-----------Configuring Oracle Database-------------"
echo "Make directories for database datafiles and flash recovery area"
[[ ! -d $DATA_DIR ]] && mkdir -p $DATA_DIR
[[ ! -d $ORACLE_MOUNT/flash_recovery_area ]] && mkdir $ORACLE_MOUNT/flash_recovery_area
chown -R oracle:oinstall $DATA_DIR
chown -R oracle:oinstall $ORACLE_MOUNT/flash_recovery_area
sleep 3

#Make response file for dbca;
cd ${ORACLE_HOME}
cat >dbca.rsp <<EOF
responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v19.0.0
gdbName=$ORACLE_SID
sid=$ORACLE_SID
createAsContainerDatabase=true
numberOfPDBs=1
pdbName=${ORACLE_PORCL}
pdbAdminPassword=${ORACLE_PASSWORD}
databaseConfigType=SI
RACOneNodeServiceName=
policyManaged=false
createServerPool=false
serverPoolName=
cardinality=
force=false
pqPoolName=
pqCardinality=
useLocalUndoForPDBs=
nodelist=
templateName=General_Purpose.dbc
sysPassword=Oracle19c
systemPassword=Oracle19c
oracleHomeUserPassword=
emConfiguration=NONE
emExpressPort=5500
runCVUChecks=FALSE
dbsnmpPassword=
omsHost=
omsPort=
emUser=
emPassword=
dvConfiguration=
dvUserName=
dvUserPassword=
dvAccountManagerName=
dvAccountManagerPassword=
olsConfiguration=
datafileJarLocation=
datafileDestination=${DATA_DIR}
recoveryAreaDestination=${ORACLE_MOUNT}/flash_recovery_area
storageType=FS
diskGroupName=
asmsnmpPassword=
recoveryGroupName=
characterSet=AL32UTF8
nationalCharacterSet=UTF8
registerWithDirService=
dirServiceUserName=
dirServicePassword=
walletPassword=
listeners=LISTENER
variablesFile=
variables=
initParams=
sampleSchema=
memoryPercentage=70
databaseType=MULTIPURPOSE
automaticMemoryManagement=FALSE
totalMemory=3072
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
su oracle -c "${ORACLE_HOME}/bin/dbca -silent -createDatabase -responseFile $ORACLE_HOME/dbca.rsp"
#su oracle -c "${ORACLE_HOME}/bin/dbca -silent -createDatabase -responseFile $ORACLE_HOME/dbca.rsp -J-Doracle.assistants.dbca.validate.ConfigurationParams=false"

#dbstart utility bring up at system boot time"
echo "Bring up at system boot time"
sed -i '/^$ORACLE_SID/c\$ORACLE_SID:$ORACLE_HOME:Y' /etc/oratab

#Finish Scripting
