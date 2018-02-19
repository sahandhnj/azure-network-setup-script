#!/usr/bin/env bash

IPWEB1="10.0.2.20"
IPWEB2="10.0.2.21"
IPDB1="10.0.3.20"
IPDB2="10.0.3.21"

GALERACONF='[mysqld]
query_cache_size=0
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
query_cache_type=0
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_provider=/usr/lib/galera/libgalera_smm.so
#wsrep_provider_options="gcache.size=32G"

# Galera Cluster Configuration
wsrep_cluster_name="test_cluster"
wsrep_cluster_address="gcomm://DBONE,DBTWO"

# Galera Synchronization Congifuration
wsrep_sst_method=rsync
#wsrep_sst_auth=user:pass

# Galera Node Configuration
wsrep_node_address="DBME"
wsrep_node_name="DBNAME"
'

echo -e ">"
echo -e "\t=============================================="
echo -e "\t= ESV UE2 DB Server (Mariadb-Galera) install ="
echo -e "\t=============================================="
echo -e "\t== do not use this in production!... please =="
echo -e "\t=============================================="
echo -e ">"

#shortcuts for apt-get
APTGET="apt-get -y"
APTGETSIM="apt-get -y -s"

#environment variables
TZ="Europe/Vienna"
TERM="dumb"
DEBIAN_FRONTEND="noninteractive"
export TZ=$TZ
export TERM=$TERM
export DEBIAN_FRONTEND=$DEBIAN_FRONTEND

#mariadb repo
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
add-apt-repository -y 'deb http://mirror.23media.de/mariadb/repo/10.0/ubuntu trusty main'

#update
$APTGET update
#$APTGET upgrade

#install mariadb galera cluster
$APTGET install mariadb-galera-server-10.0 galera rsync

#copy galera config file
mkdir -p /etc/mysql/conf.d/
touch /etc/mysql/conf.d/cluster.cnf
echo -e "$GALERACONF" > /etc/mysql/conf.d/cluster.cnf

#variables
DBME=`hostname  -I | cut -f1 -d' '`

if [ "$DBME" == "$IPDB1" ]
	then
	DBNAME="esv-db-1"
elif [ "$DBME" == "$IPDB2" ]
	then
	DBNAME="esv-db-2"
else
	echo "FATAL ERROR WRONG IP"
	#exit
fi

echo "My name is $DBNAME"

#put variables into config file
perl -pi -w -e "s/DBONE/$IPDB1/g;" /etc/mysql/conf.d/cluster.cnf
perl -pi -w -e "s/DBTWO/$IPDB2/g;" /etc/mysql/conf.d/cluster.cnf
perl -pi -w -e "s/DBME/$DBME/g;" /etc/mysql/conf.d/cluster.cnf
perl -pi -w -e "s/DBNAME/$DBNAME/g;" /etc/mysql/conf.d/cluster.cnf

#read config file
cat /etc/mysql/conf.d/cluster.cnf

service mysql stop

service mysql start --wsrep-new-cluster

mysql -u root -e 'SELECT VARIABLE_VALUE as "cluster size" FROM INFORMATION_SCHEMA.GLOBAL_STATUS WHERE VARIABLE_NAME="wsrep_cluster_size"'

if [ "$DBME" == "$IPDB1" ]
	then
	mysql -u root -e "create user \"esv\"@\"%\" identified by 'enterpriseservices'"
	mysql -u root -e 'create database wordpress'
	mysql -u root -e 'grant all privileges on wordpress.* to esv@"%"'
elif [ "$DBME" == "$IPDB2" ]
	then
	#nothing
fi

ufw default deny

ufw allow ssh
ufw allow 3306
ufw allow 4567
ufw allow 4568
ufw allow 4444

ufw --force enable
ufw reload

reboot

exit 0
