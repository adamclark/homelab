#!/bin/bash

source 00-set-vars.sh

# Create the bootstrap node:
virt-install --name ${CLUSTER_NAME}-bootstrap \
  --disk size=50 --ram 16000 --cpu host --vcpus 4 \
  --os-type linux --os-variant rhel7 \
  --network network=${VIR_NET} --noreboot --noautoconsole \
  --location rhcos-install/ \
  --extra-args "nomodeset rd.neednet=1 coreos.inst=yes coreos.inst.install_dev=vda coreos.inst.image_url=http://${HOST_IP}:${WEB_PORT}/rhcos-4.3.0-x86_64-metal.raw.gz coreos.inst.ignition_url=http://${HOST_IP}:${WEB_PORT}/install_dir/bootstrap.ign"

# Create three master nodes:
for i in {1..3}
do
virt-install --name ${CLUSTER_NAME}-master-${i} \
--disk size=50 --ram 16000 --cpu host --vcpus 4 \
--os-type linux --os-variant rhel7 \
--network network=${VIR_NET} --noreboot --noautoconsole \
--location rhcos-install/ \
--extra-args "nomodeset rd.neednet=1 coreos.inst=yes coreos.inst.install_dev=vda coreos.inst.image_url=http://${HOST_IP}:${WEB_PORT}/rhcos-4.3.0-x86_64-metal.raw.gz coreos.inst.ignition_url=http://${HOST_IP}:${WEB_PORT}/install_dir/master.ign"
done

# Create two worker nodes:
for i in {1..2}
do
  virt-install --name ${CLUSTER_NAME}-worker-${i} \
  --disk size=50 --ram 8192 --cpu host --vcpus 4 \
  --os-type linux --os-variant rhel7 \
  --network network=${VIR_NET} --noreboot --noautoconsole \
  --location rhcos-install/ \
  --extra-args "nomodeset rd.neednet=1 coreos.inst=yes coreos.inst.install_dev=vda coreos.inst.image_url=http://${HOST_IP}:${WEB_PORT}/rhcos-4.3.0-x86_64-metal.raw.gz coreos.inst.ignition_url=http://${HOST_IP}:${WEB_PORT}/install_dir/worker.ign"
done

# Customise the RHEL guest image that we downloaded for the load balancer
virt-customize -a /var/lib/libvirt/images/${CLUSTER_NAME}-lb.qcow2 \
  --uninstall cloud-init \
  --ssh-inject root:file:$SSH_KEY --selinux-relabel \
  --sm-credentials "${RHNUSER}:password:${RHNPASS}" \
  --sm-register --sm-attach auto --install haproxy

# Create the load balancer VM
virt-install --import --name ${CLUSTER_NAME}-lb \
  --disk /var/lib/libvirt/images/${CLUSTER_NAME}-lb.qcow2 --memory 1024 --cpu host --vcpus 1 \
  --network network=${VIR_NET} --noreboot --noautoconsole

# Customise the RHEL guest image that we downloaded for the NFS server
virt-customize -a /var/lib/libvirt/images/${CLUSTER_NAME}-nfs.qcow2 \
  --uninstall cloud-init \
  --ssh-inject root:file:$SSH_KEY --selinux-relabel \
  --sm-credentials "${RHNUSER}:password:${RHNPASS}" \
  --sm-register --sm-attach auto

# Create the NFS server VM
virt-install --import --name ${CLUSTER_NAME}-nfs \
  --disk /var/lib/libvirt/images/${CLUSTER_NAME}-nfs.qcow2 --memory 1024 --cpu host --vcpus 1 \
  --network network=${VIR_NET} --noreboot --noautoconsole