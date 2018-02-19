#!/usr/bin/env bash

#
# Availability Sets
#

#create first availability set
azure availset create -g enterprise_wordpress3 -n enterprise_wordpress3availset1 -l northeurope

#create second availability set
azure availset create -g enterprise_wordpress3 -n enterprise_wordpress3availset2 -l northeurope
