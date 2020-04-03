#!/bin/bash

source 00-set-vars.sh

# Instruction used - https://github.com/kevchu3/openshift4-upi-homelab/blob/master/operator/image-registry/README.md

ssh nfs.${CLUSTER_NAME}.${BASE_DOM} <<EOF

    systemctl enable --now nfs-server rpcbind
    mkdir -p /exports/registry
    chmod -R 777 /exports/registry
    echo "/exports/registry *.${CLUSTER_NAME}.${BASE_DOM}(rw,sync,no_wdelay,root_squash,insecure,fsid=0)" >> /etc/exports
    exportfs -rv

EOF

export KUBECONFIG=$OCP4_INSTALL_DIR/install_dir/auth/kubeconfig

$OCP4_INSTALL_DIR/oc project openshift-image-registry
$OCP4_INSTALL_DIR/oc apply -f registry-volume.pv.yml
$OCP4_INSTALL_DIR/oc apply -f registry-volume.pvc.yml
$OCP4_INSTALL_DIR/oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed","storage":{"claim":"image-registry-storage"}}}'