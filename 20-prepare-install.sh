#!/bin/bash

source 00-set-vars.sh

# Enable Metwork Manager's dnsmasq
echo -e "[main]\ndns=dnsmasq" > /etc/NetworkManager/conf.d/nm-dns.conf
systemctl restart NetworkManager

# Create a new directory to keep things clean:
mkdir $OCP4_INSTALL_DIR

# Download the RHCOS Install kernel and initramfs and generate the treeinfo.
mkdir $OCP4_INSTALL_DIR/rhcos-install
wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.3/4.3.0/rhcos-4.3.0-x86_64-installer-kernel -O $OCP4_INSTALL_DIR/rhcos-install/vmlinuz
wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.3/4.3.0/rhcos-4.3.0-x86_64-installer-initramfs.img -O $OCP4_INSTALL_DIR/rhcos-install/initramfs.img
    
cat <<EOF > $OCP4_INSTALL_DIR/rhcos-install/.treeinfo
[general]
arch = x86_64
family = Red Hat CoreOS
platforms = x86_64
version = 4.3.0
[images-x86_64]
initrd = initramfs.img
kernel = vmlinuz
EOF

# Download the RHCOS bios image:
wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.3/4.3.0/rhcos-4.3.0-x86_64-metal.raw.gz -O $OCP4_INSTALL_DIR/rhcos-4.3.0-x86_64-metal.raw.gz

# Download and extract the OpenShift client and install binaries
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.3.0/openshift-install-linux-4.3.0.tar.gz -O $OCP4_INSTALL_DIR/openshift-install-linux-4.3.0.tar.gz
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.3.0/openshift-client-linux-4.3.0.tar.gz -O $OCP4_INSTALL_DIR/openshift-client-linux-4.3.0.tar.gz
    
tar xf $OCP4_INSTALL_DIR/openshift-client-linux-4.3.0.tar.gz -C $OCP4_INSTALL_DIR/
tar xf $OCP4_INSTALL_DIR/openshift-install-linux-4.3.0.tar.gz -C $OCP4_INSTALL_DIR/
rm -f $OCP4_INSTALL_DIR/README.md

# Create the installation directory for the OpenShift installer
mkdir $OCP4_INSTALL_DIR/install_dir

# Generate the install-config.yaml
cat <<EOF > $OCP4_INSTALL_DIR/install_dir/install-config.yaml
apiVersion: v1
baseDomain: ${BASE_DOM}
compute:
- hyperthreading: Disabled
  name: worker
  replicas: 0
controlPlane:
  hyperthreading: Disabled
  name: master
  replicas: 3
metadata:
  name: ${CLUSTER_NAME}
networking:
  clusterNetworks:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
pullSecret: '${PULL_SEC}'
sshKey: '$(cat $SSH_KEY)'
EOF

# Generate the ignition files
$OCP4_INSTALL_DIR/openshift-install create ignition-configs --dir=$OCP4_INSTALL_DIR/install_dir

# Start python’s webserver, serving the current directory in screen:
python3 -m http.server ${WEB_PORT} &

# Make sure that the VMs can access the host on the web port. Remove this if you don’t have iptables/firewalld turned on.
# If using firewalld
firewall-cmd --add-source=${HOST_NET}
firewall-cmd --add-port=${WEB_PORT}/tcp
    
# If using iptables
iptables -I INPUT -p tcp -m tcp --dport ${WEB_PORT} -s ${HOST_NET} -j ACCEPT

# We will tell dnsmasq to treat our cluster domain . as local.
echo "local=/${CLUSTER_NAME}.${BASE_DOM}/" > ${DNS_DIR}/${CLUSTER_NAME}.conf