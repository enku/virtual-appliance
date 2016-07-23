set -ev

# (possibly) build the kernel

current_kernel=$(emerge -qp ${KERNEL}|awk '{print $4}'|cut -d/ -f2|sed s/"${KERNEL}-//;s/-r[1-9]\+$//")
echo $current_kernel

# If there is already a kernel in /boot and emerging the kernel only
# re-installs the same kernel, we can skip this
if [ -n "$current_kernel" ] && [ -e /boot/vmlinuz ] && \
    readlink /boot/vmlinuz | grep $current_kernel > /dev/null
then
    exit
fi

${EMERGE} ${USEPKG} --oneshot --newuse --noreplace sys-kernel/${KERNEL}
cp /root/kernel.config /usr/src/linux/.config
gcc-config 1
cd /usr/src/linux
make ${MAKEOPTS} oldconfig
make ${MAKEOPTS}
rm -rf /lib/modules/*
make ${MAKEOPTS} modules_install
rm -f /boot/vmlinuz*
make ${MAKEOPTS} install
cp -a /usr/src/linux/.config /root/kernel.config
make ${MAKEOPTS} mrproper
cd /boot
k=`/bin/ls -1 vmlinuz-*`
ln -nsf $k vmlinuz
${EMERGE} --depclean
