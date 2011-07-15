#!/bin/sh

EXTERNAL_KERNEL=$1
VIRTIO=$2
DISK_SIZE=$3
SWAP_SIZE=$4
UDEV=$5
DASH=$6
ARCH=$7

DPVER=7.4

TZ=$TIMEZONE ; export TZ

cat << EOF

 Before using this appliance, you must first configure Drupal, point your
 browser at http://${HOSTNAME}/ to configure.  The database name is "drupal"
 and the username is "drupal".  The DBMS is on localhost and requires no
 password. 
EOF
