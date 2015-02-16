#!/bin/bash

set -e
RSYNC_MIRROR=${RSYNC_MIRROR:-rsync://mirrors.rit.edu/gentoo/}
arch=$1
g_arch=$(echo ${arch}|sed 's/i.86/x86/')
rsync="rsync --no-motd"
echo -n ${arch}:

latest=/releases/${g_arch}/autobuilds/latest-stage3.txt

${rsync} ${RSYNC_MIRROR}${latest} latest-stage3.txt
file=$(egrep -v 'nomultilib|hardened|uclibc|^#' latest-stage3.txt \
       | grep ${arch}|head -n 1 \
       | cut -d ' ' -f 1)

file=/releases/${g_arch}/autobuilds/${file}
echo ${file}
${rsync} ${RSYNC_MIRROR}${file} stage3-${arch}-latest.tar.bz2
