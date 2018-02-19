#!/usr/bin/env bash

#GROUPNAME="$PREVGROUPNAME""x"
#echo $GROUPNAME > previousgroupname.txt
LOCATION="westeurope"
GROUPNAME="enterprise_wordpress"
VNETNAME="enterprise_wordpress_vnet"
SUB_WEB="enterprise_wordpress_subnet_web"
SUB_DB="enterprise_wordpress_subnet_db"

#Network Security Groups

#set NSGs vars
NSG_WEB1="enterprise_wordpress_nsg_web1"
NSG_WEB2="enterprise_wordpresS_nsg_web2"
NSG_WEB3="enterprise_wordpress_nsg_web3"
NSG_DB1="enterprise_wordpress_db1"
NSG_DB2="enterprise_wordpress_db2"

#set NSGs rule vars WEB1
NSG_WEB1_RULE_INBOUND_80="enterprise_wordpress_nsg_inbound_80"
NSG_WEB1_RULE_OUTBOUND_80="enterprise_wordpress_nsg_outbound_80"

NSG_WEB2_RULE_INBOUND_443="enterprise_wordpress_nsg_inbound_443"
NSG_WEB2_RULE_OUTBOUND_443="enterprise_wordpress_nsg_outbound_443"

NSG_WEB3_RULE_INBOUND_22="enterprise_wordpress_nsg_inbound_22"
NSG_WEB3_RULE_OUTBOUND_22="enterprise_wordpress_nsg_outbound_22"

NSG_DB1_RULE_INBOUND_3306="enterprise_wordpress_nsg_outbound_3306"

NSG_DB2_RULE_INBOUND_22="enterprise_wordpress_nsg_outbound_22"
NSG_DB2_RULE_OUTBOUND_22="enterprise_wordpress_nsg_outbound_22"


#create NSGs
azure network nsg create -g $GROUPNAME -n $NSG_WEB1 -l $LOCATION
azure network nsg create -g $GROUPNAME -n $NSG_WEB2 -l $LOCATION
azure network nsg create -g $GROUPNAME -n $NSG_WEB3 -l $LOCATION
azure network nsg create -g $GROUPNAME -n $NSG_DB1 -l $LOCATION
azure network nsg create -g $GROUPNAME -n $NSG_DB2 -l $LOCATION

#set NSG rule for web1 // port 80 inbound/outbound
azure network nsg rule create -g $GROUPNAME -a $NSG_WEB1 -n $NSG_WEB1_RULE_INBOUND_80 -p tcp -u 80 -c Allow -y 100
azure network nsg rule  create -g $GROUPNAME -a $NSG_WEB1 -n $NSG_WEB1_RULE_OUTBOUND_80 -p tcp -o 80 -c Allow -y 100

#set NSG rule for web2 // port 443 inbound/outbound
azure network nsg rule create -g $GROUPNAME -a $NSG_WEB2 -n $NSG_WEB2_RULE_INBOUND_443 -p tcp -u 443 -c Allow -y 100
azure network nsg rule create -g $GROUPNAME -a $NSG_WEB2 -n $NSG_WEB2_RULE_OUTBOUND_443 -p tcp -o 443 -c Allow -y 100

#set NGS rule for web3 // port 22 inbound/outbound
azure network nsg rule create -g $GROUPNAME -a $NSG_WEB3 -n $NSG_WEB3_RULE_INBOUND_22 -p tcp -u 22 -c Allow -y 100
azure network nsg rule create -g $GROUPNAME -a $NSG_WEB3 -n $NSG_WEB3_RULE_OUTBOUND_22 -p tcp -o 22 -c Allow -y 100

#set NSG rule for db1 // port 3306 inbound
azure network nsg rule create -g $GROUPNAME -a $NSG_DB1 -n $NSG_DB1_RULE_INBOUND_3306 -p tcp -u 3306 -c Allow -y 100

#set NSG rule for db2 // port 22 inbound/outbound
azure network nsg rule create -g $GROUPNAME -a $NSG_DB2 -n $NSG_DB2_RULE_INBOUND_22 -p tcp -u 22 -c Allow -y 100
azure network nsg rule create -g $GROUPNAME -a $NSG_DB2 -n $NSG_DB2_RULE_OUTBOUND_22 -p tcp -o 22 -c Allow -y 100

#assign NSG WEB1/WEB2/WEB3 to web_subnet
azure network vnet subnet set -g $GROUPNAME -e $VNETNAME -n $SUB_WEB -o $NSG_WEB1
azure network vnet subnet set -g $GROUPNAME -e $VNETNAME -n $SUB_WEB -o $NSG_WEB2
azure network vnet subnet set -g $GROUPNAME -e $VNETNAME -n $SUB_WEB -o $NSG_WEB3

#assign NSG DB1/DB2 to web_db
azure network vnet subnet set -g $GROUPNAME -e $VNETNAME -n $SUB_DB -o $NSG_DB1
azure network vnet subnet set -g $GROUPNAME -e $VNETNAME -n $SUB_DB -o $NSG_DB2
