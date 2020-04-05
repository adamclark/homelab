#!/bin/bash

source 00-set-vars.sh

# Set the timezone for all the VMs
for x in bootstrap master-1 master-2 master-3 worker-1 worker-2
do
  ssh core@${x}.${CLUSTER_NAME}.${BASE_DOM} sudo timedatectl set-timezone Europe/London
done

for x in lb nfs
do
  ssh root@${x}.${CLUSTER_NAME}.${BASE_DOM} sudo timedatectl set-timezone Europe/London
done
