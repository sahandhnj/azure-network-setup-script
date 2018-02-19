#!/usr/bin/env bash

time (
	IDENTIFIER=$(md5 -q -s $(od -vAn -N4 -tu4 < /dev/urandom) | cut -c1-6)

	COMPUTE_COUNT="2"
	DATABASE_COUNT="2"

	WEB_COMPUTE_INSTANCE="Standard_A2"
	DB_COMPUTE_INSTANCE="Standard_D2"

	LOCATION="westeurope"

	touch previousgroupname.txt
	PREVGROUPNAME=$(<previousgroupname.txt)

	GROUPNAME="esv-enterprise-wordpress-$IDENTIFIER"
	echo $GROUPNAME > previousgroupname.txt

	echo $GROUPNAME
	echo $PREVGROUPNAME

	VNETNAME="enterprise_wordpress_vnet"
	VNETIP="10.0.0.0/8"

	ESVDOMAIN="esv-enterprise-wordpress-$IDENTIFIER"

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
	PIP_DB1="10.0.3.20"

	NIC_DB2="enterprise_wordpress_nic_db2"
	IP_DB2="enterprise_wordpress_ip_db2"
	PIP_DB2="10.0.3.21"

	NIC_WEB1="enterprise_wordpress_nic_web1"
	IP_WEB1="enterprise_wordpress_ip_web1"
	PIP_WEB1="10.0.2.20"

	NIC_WEB2="enterprise_wordpress_nic_web2"
	IP_WEB2="enterprise_wordpress_ip_web2"
	PIP_WEB2="10.0.2.21"

	PUBLICKEY="id_rsa.pub"
	PRIVATEKEY="id_rsa"
	OSTYPE="Linux"
	URI="Canonical:UbuntuServer:14.04.3-LTS:14.04.201509080"
	USER="azureuser"
	PASS="Pass1234!"

	#LOAD BALANCER WEB
	LB_WEB="enterprise_wordpress_lb_web"
	LB_FRONTENDIP="enterprise_wordpress_lb_frontendip"
	LB_BACKENDIP="enterprise_wordpress_lb_backendip"
	IP_WEB_FRONT="enterprise_wordpress_ip_webfront"
	LB_PROBE_WEB="enterprise_wordpress_probe_web"
	RULE_WEB1="enterprise_wordpress_rule_web1"
	RULE_WEB2="enterprise_wordpress_rule_web2"

	#LOAD BALANCER DB
	LB_DB="enterprise_wordpress_lb_db"
	LB_DB_FRONTENDIP="enterprise_wordpress_lb_dbfrontendip"
	LB_DB_BACKENDIP="enterprise_wordpress_lb_dbbackendip"
	LB_PROBE_DB="enterprise_wordpress_probe_db"
	PIP_DB_FRONT="10.0.3.25"
	RULE_DB="enterprise_wordpress_rule_db"

	#Availability Sets
	AVAILSET_WEB="enterprise_wordpress_availset_web"
	AVAILSET_DB="enterprise_wordpress_availset_db"

	echo -n "Checking for ./node_modules/azure-cli/bin/azure cli ... "
	if ! hash ./node_modules/azure-cli/bin/azure 2>/dev/null; then
		echo -e "ERROR: ./node_modules/azure-cli/bin/azure CLI not found, aborting.\n"
		exit
	else
		echo -e $(command -v azure)
	fi

	#settings
	./node_modules/azure-cli/bin/azure config mode arm
	./node_modules/azure-cli/bin/azure provider register Microsoft.Network
	./node_modules/azure-cli/bin/azure provider register Microsoft.Storage
	./node_modules/azure-cli/bin/azure provider register Microsoft.Compute

	#delete group
	./node_modules/azure-cli/bin/azure group delete -q -n $GROUPNAME
	./node_modules/azure-cli/bin/azure group delete -q -n $PREVGROUPNAME &

	#create group
	./node_modules/azure-cli/bin/azure group create -n $GROUPNAME -l $LOCATION

	#create vnet
	./node_modules/azure-cli/bin/azure network vnet create -g $GROUPNAME -n $VNETNAME -l $LOCATION -a $VNETIP

	#create subnets
	./node_modules/azure-cli/bin/azure network vnet subnet create -g $GROUPNAME -e $VNETNAME -n $SUB_MGMT -a $SUB_MGMT_IP
	./node_modules/azure-cli/bin/azure network vnet subnet create -g $GROUPNAME -e $VNETNAME -n $SUB_WEB -a $SUB_WEB_IP
	./node_modules/azure-cli/bin/azure network vnet subnet create -g $GROUPNAME -e $VNETNAME -n $SUB_DB -a $SUB_DB_IP

	#create availability sets
	./node_modules/azure-cli/bin/azure availset create -g $GROUPNAME -n $AVAILSET_WEB -l $LOCATION
	./node_modules/azure-cli/bin/azure availset create -g $GROUPNAME -n $AVAILSET_DB -l $LOCATION

	#create and configure load balancer web
	./node_modules/azure-cli/bin/azure network public-ip create -g $GROUPNAME -n $IP_WEB_FRONT -l $LOCATION -d "$ESVDOMAIN""-frontend"
	./node_modules/azure-cli/bin/azure network lb create $GROUPNAME -n $LB_WEB -l $LOCATION
	./node_modules/azure-cli/bin/azure network lb frontend-ip create -g $GROUPNAME -n $LB_FRONTENDIP -l $LB_WEB -i $IP_WEB_FRONT
	./node_modules/azure-cli/bin/azure network lb address-pool create -g $GROUPNAME -n $LB_BACKENDIP -l $LB_WEB
	./node_modules/azure-cli/bin/azure network lb rule create -g $GROUPNAME -l $LB_WEB -n $RULE_WEB1 -p tcp -f 80 -b 80 -o $LB_BACKEDNIP -t $LB_FRONTENDIP -i 10
	./node_modules/azure-cli/bin/azure network lb rule create -g $GROUPNAME -l $LB_WEB -n $RULE_WEB2 -p tcp -f 443 -b 443 -o $LB_BACKEDNIP -t $LB_FRONTENDIP -i 10

	#create and configure load balancer DB
	./node_modules/azure-cli/bin/azure network lb create $GROUPNAME -n $LB_DB -l $LOCATION
	./node_modules/azure-cli/bin/azure network lb frontend-ip create -g $GROUPNAME -n $LB_DB_FRONTENDIP -l $LB_DB -e $SUB_DB -m $VNETNAME -a $PIP_DB_FRONT
	./node_modules/azure-cli/bin/azure network lb address-pool create -g $GROUPNAME -n $LB_DB_BACKENDIP -l $LB_DB
	./node_modules/azure-cli/bin/azure network lb rule create -g $GROUPNAME -l $LB_DB -n $RULE_DB -p tcp -f 3306 -b 3306 -o $LB_DB_BACKEDNIP -i 10

	#create public IPs for VMs
	./node_modules/azure-cli/bin/azure network public-ip create -g $GROUPNAME -n $IP_WEB1 -l $LOCATION -d "$ESVDOMAIN""-web1"
	./node_modules/azure-cli/bin/azure network public-ip create -g $GROUPNAME -n $IP_WEB2 -l $LOCATION -d "$ESVDOMAIN""-web2"
	./node_modules/azure-cli/bin/azure network public-ip create -g $GROUPNAME -n $IP_DB1 -l $LOCATION -d "$ESVDOMAIN""-db1"
	./node_modules/azure-cli/bin/azure network public-ip create -g $GROUPNAME -n $IP_DB2 -l $LOCATION -d "$ESVDOMAIN""-db2"

	#create NICs
	./node_modules/azure-cli/bin/azure network nic create -g $GROUPNAME -n $NIC_WEB1 -l $LOCATION -k $SUB_WEB -m $VNETNAME -p $IP_WEB1 -a $PIP_WEB1
	./node_modules/azure-cli/bin/azure network nic create -g $GROUPNAME -n $NIC_WEB2 -l $LOCATION -k $SUB_WEB -m $VNETNAME -p $IP_WEB2 -a $PIP_WEB2
	./node_modules/azure-cli/bin/azure network nic create -g $GROUPNAME -n $NIC_DB1 -l $LOCATION -k $SUB_DB -m $VNETNAME -p $IP_DB1 -a $PIP_DB1
	./node_modules/azure-cli/bin/azure network nic create -g $GROUPNAME -n $NIC_DB2 -l $LOCATION -k $SUB_DB -m $VNETNAME -p $IP_DB2 -a $PIP_DB2


	#Adding NICs to rules
	./node_modules/azure-cli/bin/azure network nic address-pool add -g $GROUPNAME -n $NIC_WEB1 -l $LB_WEB -a $LB_BACKENDIP
	./node_modules/azure-cli/bin/azure network nic address-pool add -g $GROUPNAME -n $NIC_WEB2 -l $LB_WEB -a $LB_BACKENDIP
	./node_modules/azure-cli/bin/azure network nic address-pool add -g $GROUPNAME -n $NIC_DB1 -l $LB_DB -a $LB_DB_BACKENDIP
	./node_modules/azure-cli/bin/azure network nic address-pool add -g $GROUPNAME -n $NIC_DB2 -l $LB_DB -a $LB_DB_BACKENDIP

	#create VMs
	./node_modules/azure-cli/bin/azure vm create -g $GROUPNAME -l $LOCATION -n $VM_WEB1 -y  $OSTYPE  -Q $URI -z $WEB_COMPUTE_INSTANCE -u $USER -p $PASS -N $NIC_WEB1 -M $PUBLICKEY -r $AVAILSET_WEB
	./node_modules/azure-cli/bin/azure vm create -g $GROUPNAME -l $LOCATION -n $VM_WEB2 -y  $OSTYPE  -Q $URI -z $WEB_COMPUTE_INSTANCE -u $USER -p $PASS -N $NIC_WEB2 -M $PUBLICKEY -r $AVAILSET_WEB
	./node_modules/azure-cli/bin/azure vm create -g $GROUPNAME -l $LOCATION -n $VM_DB1 -y  $OSTYPE  -Q $URI -z $DB_COMPUTE_INSTANCE -u $USER -p $PASS -N $NIC_DB1 -M $PUBLICKEY -r $AVAILSET_DB
	./node_modules/azure-cli/bin/azure vm create -g $GROUPNAME -l $LOCATION -n $VM_DB2 -y  $OSTYPE  -Q $URI -z $DB_COMPUTE_INSTANCE -u $USER -p $PASS -N $NIC_DB2 -M $PUBLICKEY -r $AVAILSET_DB

	#set extensions
	./node_modules/azure-cli/bin/azure vm extension set $GROUPNAME $VM_DB1 CustomScriptForLinux Microsoft.OSTCExtensions 1.3 -c conf-db.json
	./node_modules/azure-cli/bin/azure vm extension set $GROUPNAME $VM_DB2 CustomScriptForLinux Microsoft.OSTCExtensions 1.3 -c conf-db.json
	./node_modules/azure-cli/bin/azure vm extension set $GROUPNAME $VM_WEB1 CustomScriptForLinux Microsoft.OSTCExtensions 1.3 -c conf-web.json
	./node_modules/azure-cli/bin/azure vm extension set $GROUPNAME $VM_WEB2 CustomScriptForLinux Microsoft.OSTCExtensions 1.3 -c conf-web.json

	#show
	./node_modules/azure-cli/bin/azure vm show -g $GROUPNAME -n $VM_WEB1
	./node_modules/azure-cli/bin/azure vm show -g $GROUPNAME -n $VM_WEB2
	./node_modules/azure-cli/bin/azure vm show -g $GROUPNAME -n $VM_DB1
	./node_modules/azure-cli/bin/azure vm show -g $GROUPNAME -n $VM_DB2
	./node_modules/azure-cli/bin/azure network lb show -g $GROUPNAME -n $LB_WEB
	./node_modules/azure-cli/bin/azure network lb show -g $GROUPNAME -n $LB_PROBE_WEB

	echo "$ESVDOMAIN"
	wait
	exit 0
)
