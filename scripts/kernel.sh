set -ev

# (possibly) build the kernel

current_kernel=""
if [ -d "/var/db/pkg/sys-kernel" ]
then
    cd "/var/db/pkg/sys-kernel"
    current_kernel=`/bin/ls -d1 "${KERNEL}-"* | tail -n 1|sed s/"${KERNEL}-//;s/-r[1-9]\+$//"`
fi

# If there is already a kernel in /boot and emerging the kernel only
# re-installs the same package, we can skip this
if [ -n "$current_kernel" ] && [ -e /boot/vmlinuz ] && \
    readlink /boot/vmlinuz | grep $current_kernel > /dev/null
then
    exit
fi

${EMERGE} ${USEPKG} -Nn sys-kernel/${KERNEL}
cp /root/kernel.config /usr/src/linux/.config
gcc-config 1
cd /usr/src/linux
make ${MAKEOPTS} oldconfig
make ${MAKEOPTS}
rm -rf /lib/modules/*
make ${MAKEOPTS} modules_install
rm -f /boot/vmlinuz*
make ${MAKEOPTS} install
cd /boot
k=`/bin/ls -1 vmlinuz-*`
ln -nsf $k vmlinuz
cp -a /usr/src/linux/.config /root/kernel.config
${EMERGE} --depclean
