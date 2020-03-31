#!/bin/bash

source 00-set-vars.sh

# Start all the VMs
for x in lb bootstrap master-1 master-2 master-3 worker-1 worker-2 nfs
do
  virsh start ${CLUSTER_NAME}-$x
done