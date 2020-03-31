#!/bin/bash

source 00-set-vars.sh

# Find the IP and MAC address of the bootstrap VM. Add DHCP reservation (so the VM always get the same IP) and an entry in /etc/hosts:
IP=$(virsh domifaddr "${CLUSTER_NAME}-bootstrap" | grep ipv4 | head -n1 | awk '{print $4}' | cut -d'/' -f1)
MAC=$(virsh domifaddr "${CLUSTER_NAME}-bootstrap" | grep ipv4 | head -n1 | awk '{print $2}')
virsh net-update ${VIR_NET} add-last ip-dhcp-host --xml "<host mac='$MAC' ip='$IP'/>" --live --config
echo "$IP bootstrap.${CLUSTER_NAME}.${BASE_DOM}" >> /etc/hosts

# Find the IP and MAC address of the master VMs. Add DHCP reservation (so the VMs always gets the same IP), and an entry in /etc/hosts. We will also add the corresponding etcd host and SRV record:
for i in {1..3}
do
  IP=$(virsh domifaddr "${CLUSTER_NAME}-master-${i}" | grep ipv4 | head -n1 | awk '{print $4}' | cut -d'/' -f1)
  MAC=$(virsh domifaddr "${CLUSTER_NAME}-master-${i}" | grep ipv4 | head -n1 | awk '{print $2}')
  virsh net-update ${VIR_NET} add-last ip-dhcp-host --xml "<host mac='$MAC' ip='$IP'/>" --live --config
  echo "$IP master-${i}.${CLUSTER_NAME}.${BASE_DOM}" \
  "etcd-$((i-1)).${CLUSTER_NAME}.${BASE_DOM}" >> /etc/hosts
  echo "srv-host=_etcd-server-ssl._tcp.${CLUSTER_NAME}.${BASE_DOM},etcd-$((i-1)).${CLUSTER_NAME}.${BASE_DOM},2380,0,10" >> ${DNS_DIR}/${CLUSTER_NAME}.conf
done

# Find the IP and MAC address of the worker VMs. Add DHCP reservation (so the VM always get the same IP) and an entry in /etc/hosts.
for i in {1..2}
do
   IP=$(virsh domifaddr "${CLUSTER_NAME}-worker-${i}" | grep ipv4 | head -n1 | awk '{print $4}' | cut -d'/' -f1)
   MAC=$(virsh domifaddr "${CLUSTER_NAME}-worker-${i}" | grep ipv4 | head -n1 | awk '{print $2}')
   virsh net-update ${VIR_NET} add-last ip-dhcp-host --xml "<host mac='$MAC' ip='$IP'/>" --live --config
   echo "$IP worker-${i}.${CLUSTER_NAME}.${BASE_DOM}" >> /etc/hosts
done

# Find the IP and MAC address of the load balancer VM. Add DHCP reservation (so the VM always get the same IP) and an entry in /etc/hosts. We will also add the api and api-int host records as they should point to this load balancer.
LBIP=$(virsh domifaddr "${CLUSTER_NAME}-lb" | grep ipv4 | head -n1 | awk '{print $4}' | cut -d'/' -f1)
MAC=$(virsh domifaddr "${CLUSTER_NAME}-lb" | grep ipv4 | head -n1 | awk '{print $2}')
virsh net-update ${VIR_NET} add-last ip-dhcp-host --xml "<host mac='$MAC' ip='$LBIP'/>" --live --config
echo "$LBIP lb.${CLUSTER_NAME}.${BASE_DOM}" \
"api.${CLUSTER_NAME}.${BASE_DOM}" \
"api-int.${CLUSTER_NAME}.${BASE_DOM}" >> /etc/hosts

# Create the wild-card DNS record and point it to the load balancer:
echo "address=/apps.${CLUSTER_NAME}.${BASE_DOM}/${LBIP}" >> ${DNS_DIR}/${CLUSTER_NAME}.conf

# Find the IP and MAC address of the NFS VM. Add DHCP reservation (so the VM always get the same IP) and an entry in /etc/hosts.
NFSIP=$(virsh domifaddr "${CLUSTER_NAME}-nfs" | grep ipv4 | head -n1 | awk '{print $4}' | cut -d'/' -f1)
MAC=$(virsh domifaddr "${CLUSTER_NAME}-nfs" | grep ipv4 | head -n1 | awk '{print $2}')
virsh net-update ${VIR_NET} add-last ip-dhcp-host --xml "<host mac='$MAC' ip='$NFSIP'/>" --live --config
echo "$NFSIP nfs.${CLUSTER_NAME}.${BASE_DOM}" >> /etc/hosts