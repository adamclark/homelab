#!/bin/bash

source 00-set-vars.sh

# Remove the boostrap entries from our load balancer (haproxy).
ssh lb.${CLUSTER_NAME}.${BASE_DOM} <<EOF
    sed -i '/bootstrap\.${CLUSTER_NAME}\.${BASE_DOM}/d' /etc/haproxy/haproxy.cfg
    systemctl restart haproxy
EOF

# Delete the bootstrap VM
virsh destroy ${CLUSTER_NAME}-bootstrap
virsh undefine ${CLUSTER_NAME}-bootstrap --remove-all-storage