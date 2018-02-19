#!/usr/bin/env bash

COMPUTE_COUNT="2"
DATABASE_COUNT="2"

WEB_COMPUTE_INSTANCE="Basic_A2"
DB_COMPUTE_INSTANCE="Standard_D2"

LOCATION="northeurope"
GROUPNAME="enterprise_wordpress"


VNETNAME="enterprise_wordpress_vnet"
VNETIP="10.0.0.0/8"

SUB_WEB="enterprise_wordpress_subnet_web"
SUB_WEB_IP="10.0.2.0/24"

SUB_MGMT="enterprise_wordpress_subnet_mgmt"
SUB_MGMT_IP="10.0.1.0/24"
NIC_MGMT="enterprise_wordpress_nic_mgmt"

SUB_DB="enterprise_wordpress_subnet_db"
SUB_DB_IP="10.0.3.0/24"

VM_WEB1="enterprise-wordpress-vm-web1"
VM_WEB2="enterprise-wordpress-vm-web2"
VM_DB1="enterprise-wordpress-vm-db1"
VM_DB2="enterprise-wordpress-vm-db2"

NIC_DB1="enterprise_wordpress_nic_db1"
IP_DB1="enterprise_wordpress_ip_db1"
PRIVIP_DB1="10.0.3.20"

NIC_DB2="enterprise_wordpress_nic_db2"
IP_DB2="enterprise_wordpress_ip_db2"
PRIVIP_DB2="10.0.3.21"

NIC_WEB1="enterprise_wordpress_nic_web1"
IP_WEB1="enterprise_wordpress_ip_web1"
PRIVIP_WEB1="10.0.2.20"

NIC_WEB2="enterprise_wordpress_nic_web2"
IP_WEB2="enterprise_wordpress_ip_web2"
PRIVIP_WEB2="10.0.2.21"


PUBLICKEY="id_rsa.pub"
PRIVATEKEY="id_rsa"
OSTYPE="Linux"
URI="Canonical:UbuntuServer:14.04.3-LTS:14.04.201509080"
USER="azureuser"
PASS="Pass1234!"

echo -n "Checking for azure cli ... "
if ! hash azure 2>/dev/null; then
	echo -e "ERROR: azure CLI not found, aborting.\n"
	exit
else
	echo -e $(command -v azure)
fi

#settings
azure config mode arm
azure provider register Microsoft.Network
azure provider register Microsoft.Storage
azure provider register Microsoft.Compute

#delete group
azure group delete -q -n $GROUPNAME

#set group
azure group create -n $GROUPNAME -l $LOCATION

#set ip
azure network public-ip create -g $GROUPNAME -n $IP_WEB1 -l $LOCATION -a Static &
azure network public-ip create -g $GROUPNAME -n $IP_WEB2 -l $LOCATION -a Static &
azure network public-ip create -g $GROUPNAME -n $IP_DB1 -l $LOCATION -a Static &
azure network public-ip create -g $GROUPNAME -n $IP_DB2 -l $LOCATION -a Static &

#set vnet
azure network vnet create -g $GROUPNAME -n $VNETNAME -l $LOCATION -a $VNETIP

for job in `jobs -p`
do
echo $job
    wait $job || let "FAIL+=1"
done

#set subnets
azure network vnet subnet create -g $GROUPNAME -e $VNETNAME -n $SUB_MGMT -a $SUB_MGMT_IP
azure network vnet subnet create -g $GROUPNAME -e $VNETNAME -n $SUB_WEB -a $SUB_WEB_IP
azure network vnet subnet create -g $GROUPNAME -e $VNETNAME -n $SUB_DB -a $SUB_DB_IP

#create nic
azure network nic create -g $GROUPNAME -n $NIC_WEB1 -l $LOCATION -k $SUB_WEB -m $VNETNAME -a $PRIVIP_WEB1
azure network nic create -g $GROUPNAME -n $NIC_WEB2 -l $LOCATION -k $SUB_WEB -m $VNETNAME -a $PRIVIP_WEB2
azure network nic create -g $GROUPNAME -n $NIC_DB1 -l $LOCATION -k $SUB_DB -m $VNETNAME -a $PRIVIP_DB1
azure network nic create -g $GROUPNAME -n $NIC_DB2 -l $LOCATION -k $SUB_DB -m $VNETNAME -a $PRIVIP_DB2

azure vm create -g $GROUPNAME -l $LOCATION -n $VM_WEB1 -y  $OSTYPE  -Q $URI -z $WEB_COMPUTE_INSTANCE -u $USER -p $PASS -N $NIC_WEB1 -M $PUBLICKEY -i $IP_WEB1
azure vm create -g $GROUPNAME -l $LOCATION -n $VM_WEB2 -y  $OSTYPE  -Q $URI -z $WEB_COMPUTE_INSTANCE -u $USER -p $PASS -N $NIC_WEB2 -M $PUBLICKEY -i $IP_WEB2
azure vm create -g $GROUPNAME -l $LOCATION -n $VM_DB1 -y  $OSTYPE  -Q $URI -z $DB_COMPUTE_INSTANCE -u $USER -p $PASS -N $NIC_DB1 -M $PUBLICKEY -i $IP_DB1
azure vm create -g $GROUPNAME -l $LOCATION -n $VM_DB2 -y  $OSTYPE  -Q $URI -z $DB_COMPUTE_INSTANCE -u $USER -p $PASS -N $NIC_DB2 -M $PUBLICKEY -i $IP_DB2

ssh -i $PRIVATEKEY azureuser@$IP_WEB1 "cat | sudo bash" < ./webserver/install-webserver.sh
ssh -i $PRIVATEKEY azureuser@$IP_WEB2 "cat | sudo bash" < ./webserver/install-webserver.sh
ssh -i $PRIVATEKEY azureuser@$IP_DB1 "cat | sudo bash" < ./dbserver/install-dbserver.sh
ssh -i $PRIVATEKEY azureuser@$IP_DB2 "cat | sudo bash" < ./dbserver/install-dbserver.sh
