set -ev

# (possibly) build the kernel

# If there is already a kernel in /boot and emerging the kernel only
# re-installs the same package, we can skip this
if [ -e /boot/vmlinuz ] && emerge -pq sys-kernel/${KERNEL}|grep '^\[.*R.*\]' >/dev/null
then
    exit
fi

${EMERGE} ${USEPKG} --oneshot --noreplace dev-lang/perl
${EMERGE} ${USEPKG} sys-kernel/${KERNEL}
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
