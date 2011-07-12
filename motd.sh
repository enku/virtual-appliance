#!/bin/sh
# Script for creating the motd on a virtual appliance image

EXTERNAL_KERNEL=$1
VIRTIO=$2
DISK_SIZE=$3
SWAP_SIZE=$4
UDEV=$5
DASH=$6
ARCH=$7

TZ=$TIMEZONE ; export TZ

cat << EOF

 Welcome to ${HOSTNAME}!
 
 This system created by Gentoo Virtual Appliance:
 
               https://bitbucket.org/marduk/virtual-appliance/
 
 The system image was built on `date -u +"%Y-%m-%d %H:%M %Z"` based on the "${APPLIANCE}"
 appliance. It was built with the following features:
 
EOF
cat << EOF | column -c80
 APPLIANCE: ${APPLIANCE}
 ARCH: ${ARCH}
 HOSTNAME: ${HOSTNAME}
 HEADLESS: ${HEADLESS}
 EXTERNAL_KERNEL: ${EXTERNAL_KERNEL}
 VIRTIO: ${VIRTIO}
 DISK_SIZE: ${DISK_SIZE}
 SWAP_SIZE: ${SWAP_SIZE}M
 UDEV: ${UDEV}
 DASH: ${DASH}
EOF
echo
