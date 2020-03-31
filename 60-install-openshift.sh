#!/bin/bash

source 00-set-vars.sh

# Reload NetworkManager and Libvirt for DNS entries to be loaded properly:
systemctl reload NetworkManager
systemctl restart libvirtd

# Start the OpenShift installation, breaking at bootrap completion:
$OCP4_INSTALL_DIR/openshift-install --dir=$OCP4_INSTALL_DIR/install_dir wait-for bootstrap-complete

$OCP4_INSTALL_DIR/openshift-install --dir=$OCP4_INSTALL_DIR/install_dir wait-for install-complete
