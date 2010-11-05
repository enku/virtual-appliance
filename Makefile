
APPLIANCE=base
HOSTNAME=$(APPLIANCE)
RAW_IMAGE=$(HOSTNAME).img
QCOW_IMAGE=$(HOSTNAME).qcow
VMDK_IMAGE=$(HOSTNAME).vmdk
KERNEL_CONFIG = kernel.config
VIRTIO=NO
TIMEZONE=UTC
DISK_SIZE=6.0G
SWAP_SIZE=30
CHROOT=chroot
ARCH=amd64
MAKEOPTS=-j4
PRUNE_CRITICAL=NO
HEADLESS=NO
ACCEPT_KEYWORDS="amd64"

INSTALL=install
M4=m4
M4_DEFS=-D HOSTNAME=$(HOSTNAME)
M4C=$(M4) $(M4_DEFS)
NBD_DEV=/dev/nbd0
PKGDIR =
USEPKG=--usepkg --binpkg-respect-use=y
RSYNC_MIRROR = rsync://mirrors.rit.edu/gentoo/
KERNEL=gentoo-sources
PACKAGE_FILES=$(APPLIANCE)/package.*
WORLD=$(APPLIANCE)/world
CRITICAL=$(APPLIANCE)/critical

include $(APPLIANCE)/Makefile.inc

all: image

$(RAW_IMAGE):
	qemu-img create -f raw $(RAW_IMAGE) $(DISK_SIZE)

partitions: $(RAW_IMAGE)
	parted -s  $(RAW_IMAGE) mklabel msdos
	parted -s  $(RAW_IMAGE) mkpart primary ext2 0 $(DISK_SIZE)
	parted -s  $(RAW_IMAGE) set 1 boot on

	qemu-nbd -c $(NBD_DEV) $(RAW_IMAGE)
	sleep 3
	mkfs.ext2 -O sparse_super -L "$(APPLIANCE)" $(NBD_DEV)p1
	touch partitions

$(CHROOT):
	mkdir -p $(CHROOT)

mounts: $(CHROOT) stage3
	if [ ! -e mounts ] ; then \
		mount -t proc none $(CHROOT)/proc; \
		mount -o bind /dev $(CHROOT)/dev; \
		mount -o bind /var/tmp $(CHROOT)/var/tmp; \
	fi
	touch mounts

portage: stage3
	rsync -L $(RSYNC_MIRROR)/snapshots/portage-latest.tar.bz2 portage-latest.tar.bz2
	tar xjf portage-latest.tar.bz2 -C $(CHROOT)/usr
	if [ -n "$(PKGDIR)" ]; then \
		mkdir -p $(CHROOT)/usr/portage/packages; \
		mount -o bind "$(PKGDIR)" $(CHROOT)/usr/portage/packages; \
	fi
	touch portage

preproot: stage3 mounts portage
	cp -L /etc/resolv.conf $(CHROOT)/etc/
	touch preproot

stage3: chroot
	rsync $(RSYNC_MIRROR)/releases/$(ARCH)/autobuilds/latest-stage3.txt .
	rsync $(RSYNC_MIRROR)/releases/$(ARCH)/autobuilds/`tail -n 1 latest-stage3.txt` .
	stage3=`tail -n 1 latest-stage3.txt` ; tar xjpf `basename $$stage3` -C $(CHROOT)
	touch stage3

compile_options: portage make.conf locale.gen $(PACKAGE_FILES)
	cp make.conf $(CHROOT)/etc/make.conf
	echo ACCEPT_KEYWORDS=$(ACCEPT_KEYWORDS) >> $(CHROOT)/etc/make.conf
	cp locale.gen $(CHROOT)/etc/locale.gen
	chroot $(CHROOT) locale-gen
	mkdir -p $(CHROOT)/etc/portage
	for f in $(PACKAGE_FILES) ; do \
		cp $$f $(CHROOT)/etc/portage/ ; \
	done
	touch compile_options

base_system: mounts compile_options
	touch base_system

$(CHROOT)/boot/vmlinuz: base_system $(KERNEL_CONFIG)
	chroot $(CHROOT) cp /usr/share/zoneinfo/$(TIMEZONE) /etc/localtime
	chroot $(CHROOT) emerge -n $(USEPKG) sys-kernel/$(KERNEL)
	cp $(KERNEL_CONFIG) $(CHROOT)/usr/src/linux/.config
	chroot $(CHROOT) gcc-config 1
	chroot $(CHROOT) make $(MAKEOPTS) -C /usr/src/linux oldconfig
	chroot $(CHROOT) make $(MAKEOPTS) -C /usr/src/linux
	chroot $(CHROOT) make $(MAKEOPTS) -C /usr/src/linux modules_install
	chroot $(CHROOT) make $(MAKEOPTS) -C /usr/src/linux install
	cd $(CHROOT)/boot ; \
		k=`/bin/ls -1 --sort=time vmlinuz-*|head -n 1` ; \
		ln -nsf $$k vmlinuz

sysconfig: preproot fstab
	cp fstab $(CHROOT)/etc/fstab
	if [ "$(VIRTIO)" == "YES" ] ; then \
		sed -i 's/sda/vda/' $(CHROOT)/etc/fstab; \
	fi
	dd if=/dev/zero of=$(CHROOT)/.swap bs=1M count=$(SWAP_SIZE)
	/sbin/mkswap $(CHROOT)/.swap
	echo HOSTNAME=$(HOSTNAME) > $(CHROOT)/etc/conf.d/hostname
	sed -i 's/^#TIMEZONE=.*/TIMEZONE="$(TIMEZONE)"/' $(CHROOT)/etc/conf.d/clock
	sed -i 's/^#s0:/s0:/' $(CHROOT)/etc/inittab
	if [ "$(HEADLESS)" == "YES" ] ; then \
	    sed -i 's/^\(c[0-9]:\)/#\1/' $(CHROOT)/etc/inittab ; \
	fi
	echo 'config_eth0=( "dhcp" )' > $(CHROOT)/etc/conf.d/net
	chroot $(CHROOT) rc-update add net.eth0 default
	chroot $(CHROOT) rc-update del consolefont boot
	touch sysconfig

systools: sysconfig compile_options
	chroot $(CHROOT) emerge -n $(USEPKG) app-admin/syslog-ng
	chroot $(CHROOT) rc-update add syslog-ng default
	chroot $(CHROOT) emerge -n $(USEPKG) sys-power/acpid
	chroot $(CHROOT) rc-update add acpid default
	chroot $(CHROOT) emerge -n $(USEPKG) net-misc/dhcpcd
	touch systools

grub: systools grub.conf $(CHROOT)/boot/vmlinuz
	chroot $(CHROOT) emerge -nN $(USEPKG) sys-boot/grub
	cp grub.conf $(CHROOT)/boot/grub/grub.conf
	if [ "$(VIRTIO)" == "YES" ] ; then \
		sed -i 's/sda/vda/' $(CHROOT)/boot/grub/grub.conf ; \
	fi
	if [ "$(HEADLESS)" == "YES" ] ; then \
	    sed -i -f grub-headless.sed $(CHROOT)/boot/grub/grub.conf ; \
	fi
	touch grub

software: systools issue etc-update.conf $(CRITICAL) $(WORLD)
	$(preinstall)
	#chroot $(CHROOT) emerge -DN $(USEPKG) system
	cp etc-update.conf $(CHROOT)/etc/
	cat $(WORLD) >> $(CHROOT)/var/lib/portage/world
	#chroot $(CHROOT) emerge -DNn $(USEPKG) `cat $(WORLD)`
	chroot $(CHROOT) emerge $(USEPKG) --update --newuse --deep world
	chroot $(CHROOT) emerge -1n app-portage/gentoolkit
	chroot $(CHROOT) revdep-rebuild -i
	cp issue $(CHROOT)/etc/issue
	chroot $(CHROOT) emerge --depclean --with-bdeps=n
	chroot $(CHROOT) etc-update
	chroot $(CHROOT) gcc-config 1
	$(postinstall)
	chroot $(CHROOT) passwd -d root
	chroot $(CHROOT) passwd -e root
	if [ "$(PRUNE_CRITICAL)" = "YES" ] ; then \
		chroot $(CHROOT) emerge -C `cat $(CRITICAL)` ; \
	fi
	touch software

device-map: $(RAW_IMAGE)
	echo '(hd0) ' $(RAW_IMAGE) > device-map

image: $(RAW_IMAGE) grub partitions device-map grub.shell systools software
	mkdir -p loop
	mount -o noatime $(NBD_DEV)p1 loop
	mkdir -p gentoo
	mount -o bind $(CHROOT) gentoo
	if [ "$(PRUNE_CRITICAL)" = "YES" ] ; then \
		rsync -ax --exclude-from=rsync-excludes --exclude-from=rsync-excludes-critical gentoo/ loop/ ; \
	else \
		rsync -ax --exclude-from=rsync-excludes gentoo/ loop/ ; \
	fi
	loop/sbin/grub --device-map=device-map --no-floppy --batch < grub.shell
	umount gentoo
	rmdir gentoo
	umount loop
	sleep 3
	rmdir loop
	qemu-nbd -d $(NBD_DEV)
	touch image

$(QCOW_IMAGE): $(RAW_IMAGE) image
	qemu-img convert -f raw -O qcow2 -c $(RAW_IMAGE) $(QCOW_IMAGE)

qcow: $(QCOW_IMAGE)


$(VMDK_IMAGE): $(RAW_IMAGE) image
	qemu-img convert -f raw -O vmdk $(RAW_IMAGE) $(VMDK_IMAGE)

vmdk: $(VMDK_IMAGE)

umount: 
	umount -l $(CHROOT)/usr/portage/packages
	umount -l $(CHROOT)/var/tmp
	umount -l $(CHROOT)/dev
	umount -l $(CHROOT)/proc

clean: umount
	rm -f mounts compile_options base_system portage
	rm -f parted grub stage3 software preproot sysconfig systools image partitions device-map
	rm -rf loop
	rm -rf gentoo
	rm -rf $(CHROOT)

realclean: clean
	rm -f $(RAW_IMAGE) $(QCOW_IMAGE) $(VMDK_IMAGE)

.PHONY: qcow vmdk clean umount
