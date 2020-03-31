#!/bin/bash

nmcli con add ifname br0 type bridge con-name br0
nmcli con add type bridge-slave ifname enp3s0f0 master br0
nmcli con down enp3s0f0
nmcli con up br0
