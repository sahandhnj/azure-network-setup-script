#!/usr/bin/env bash

#
# Network Security Groups (NSG)
#

## Creating
#create first network security group
azure network nsg create -g enterprise_wordpress -n enterprise_wordpressnsg1 -l northeurope

#create second network security group
azure network nsg create -g enterprise_wordpress -n enterprise_wordpressnsg2 -l northeurope

## Assigning
# assign NSG to subnet <Web>
azure network vnet subnet set -g enterprise_wordpress -e enterprise_wordpress_vnet -n enterprise_wordpress_subnet_web -o enterprise_wordpressnsg1

# assign NSG to subnet <DB>
azure network vnet subnet set -g enterprise_wordpress -e enterprise_wordpress_vnet -n enterprise_wordpress_subnet_db -o enterprise_wordpressnsg2
