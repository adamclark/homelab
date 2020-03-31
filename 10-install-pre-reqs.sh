#!/bin/bash

yum -y update
yum -y install qemu-kvm qemu-img libvirt virt-install libvirt-client virt-manager libvirt-devel libvirt-daemon-kvm
systemctl enable libvirtd.service
