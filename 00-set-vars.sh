#!/bin/bash

# Pick a base domain for your cluster:
BASE_DOM="lab"

# Pick a cluster name:
CLUSTER_NAME="ocp4"

# Pick your SSH public key (file):
SSH_KEY="~/.ssh/id_rsa.pub"

# All the VMs will be created on the libvirt’s network that you pick. By default libvirt has only one “default” network.
# You can find out libvirt’s networks by running virsh net-list
VIR_NET="default"

# Set the dnsmasq configuration directory.
# If you are using NetworkManager’s embedded dnsmasq, set it to “/etc/NetworkManager/dnsmasq.d”.
# If you are using a separate dnsmasq installed on the host set it to “/etc/dnsmasq.d”.
DNS_DIR="/etc/NetworkManager/dnsmasq.d"

# Based on the libvirt’s network selected, we need to find out the Network and IP address of libvirt’s bridge interface.
HOST_NET=$(ip -4 a s $(virsh net-info $VIR_NET | awk '/Bridge:/{print $2}') | awk '/inet /{print $2}')
HOST_IP=$(echo $HOST_NET | cut -d '/' -f1)

# Download your pull secret from Red Hat OpenShift Cluster Manager (https://cloud.redhat.com/openshift/install/metal/user-provisioned) and load into a variable.
PULL_SEC=$(cat /tmp/pull-secret)

# Set the Red Hat Customer Portal credentials. We will need this when we register the RHEL guest to install haproxy.
RHNUSER='<your-rhn-user-name>'
RHNPASS='<your-rhn-password>'

# Pick a port that you want the web server to listen on
WEB_PORT="1234"
