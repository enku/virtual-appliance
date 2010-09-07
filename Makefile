
APPLIANCE=base
HOSTNAME=$(APPLIANCE)
RAW_IMAGE=$(HOSTNAME).img
QCOW_IMAGE=$(HOSTNAME).qcow
VMDK_IMAGE=$(HOSTNAME).vmdk
VIRTIO=NO
TIMEZONE=UTC
DISK_SIZE=6.0G
SWAP_SIZE=30
CHROOT=chroot
ARCH=amd64
MAKEOPTS=-j4
PRUNE_CRITICAL=NO

INSTALL=install
M4=m4
M4_DEFS=-D HOSTNAME=$(HOSTNAME)
M4C=$(M4) $(M4_DEFS)
USEPKG=--usepkg --binpkg-respect-use=y
PARTED=/usr/sbin/parted
PORTAGE=/usr/portage
STAGE3=ftp://ftp.osuosl.org/pub/gentoo/releases/$(ARCH)/autobuilds/current-stage3/stage3-$(ARCH)-*.tar.bz2
KERNEL=gentoo-sources
PACKAGE_FILES=$(APPLIANCE)/package.*
WORLD=$(APPLIANCE)/world
CRITICAL=$(APPLIANCE)/critical
PREINSTALL=$(APPLIANCE)/preinstall
POSTINSTALL=$(APPLIANCE)/postinstall


all: image

$(RAW_IMAGE):
	qemu-img create -f raw $(RAW_IMAGE) $(DISK_SIZE)

partitions: parted $(RAW_IMAGE)
	$(PARTED) -s -a optimal $(RAW_IMAGE) mklabel msdos
	$(PARTED) -s -a optimal $(RAW_IMAGE) mkpart primary ext4 0 $(DISK_SIZE)
	$(PARTED) -s -a optimal $(RAW_IMAGE) set 1 boot on

	qemu-nbd -c /dev/nbd0 $(RAW_IMAGE)
	sleep 3
	mkfs.ext4 /dev/nbd0p1
	touch partitions

parted:
	emerge -n1 $(USEPKG) parted
	touch parted

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
	if [ ! -e portage ] ; then \
		mkdir -p $(CHROOT)/usr/portage; \
		mount -o bind $(PORTAGE) $(CHROOT)/usr/portage; \
	fi
	touch portage

preproot: stage3 mounts portage
	cp -L /etc/resolv.conf $(CHROOT)/etc/
	touch preproot

stage3: chroot
	if [ ! -e stage3 ] ; then \
		wget -c -q -nc $(STAGE3); \
		tar xjpf `/bin/ls -1 stage3-*.tar.bz2|tail -n1` -C $(CHROOT); \
	fi
	# is it me or does the latest stage3 have python3 as the system
	# default?!
	chroot $(CHROOT) eselect python set python2.6
	touch stage3

compile_options: make.conf locale.gen $(PACKAGE_FILES)
	cp make.conf $(CHROOT)/etc/make.conf
	cp locale.gen $(CHROOT)/etc/locale.gen
	chroot $(CHROOT) locale-gen
	mkdir -p $(CHROOT)/etc/portage
	for f in $(PACKAGE_FILES) ; do \
		cp $$f $(CHROOT)/etc/portage/ ; \
	done
	touch compile_options

base_system: mounts compile_options
	touch base_system

kernel: $(CHROOT)/boot/vmlinuz


$(CHROOT)/boot/vmlinuz: base_system kernel.config
	chroot $(CHROOT) cp /usr/share/zoneinfo/$(TIMEZONE) /etc/localtime
	chroot $(CHROOT) emerge -N sys-kernel/$(KERNEL)
	cp kernel.config $(CHROOT)/usr/src/linux/.config
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
	echo 'config_eth0=( "dhcp" )' > $(CHROOT)/etc/conf.d/net
	chroot $(CHROOT) rc-update add net.eth0 default
	touch sysconfig

systools: sysconfig compile_options
	chroot $(CHROOT) emerge -n $(USEPKG) app-admin/syslog-ng
	chroot $(CHROOT) rc-update add syslog-ng default
	chroot $(CHROOT) emerge -n $(USEPKG) sys-power/acpid
	chroot $(CHROOT) rc-update add acpid default
	chroot $(CHROOT) emerge -n $(USEPKG) net-misc/dhcpcd
	touch systools

grub: systools grub.conf kernel
	chroot $(CHROOT) emerge -nN $(USEPKG) sys-boot/grub
	cp grub.conf $(CHROOT)/boot/grub/grub.conf
	if [ "$(VIRTIO)" == "YES" ] ; then \
		sed -i 's/sda/vda/' $(CHROOT)/boot/grub/grub.conf ; \
	fi
	touch grub

software: systools issue etc-update.conf $(CRITICAL) $(WORLD) $(PREINSTALL) $(POSTINSTALL)
	./$(PREINSTALL) "$(CHROOT)" $(HOSTNAME)
	chroot $(CHROOT) emerge -DN $(USEPKG) system
	cp etc-update.conf $(CHROOT)/etc/
	chroot $(CHROOT) etc-update
	chroot $(CHROOT) emerge -DNn $(USEPKG) `cat $(WORLD)`
	chroot $(CHROOT) emerge -1n app-portage/gentoolkit
	chroot $(CHROOT) revdep-rebuild -i
	cp issue $(CHROOT)/etc/issue
	chroot $(CHROOT) emerge --depclean --with-bdeps=n
	chroot $(CHROOT) gcc-config 1
	./$(POSTINSTALL) "$(CHROOT)" $(HOSTNAME)
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
	mount /dev/nbd0p1 loop/
	mkdir -p gentoo
	mount -o bind $(CHROOT) gentoo
	rm -rf gentoo/usr/src/linux-*
	rm -rf gentoo/tmp/*
	rm -rf gentoo/var/tmp/*
	if [ "$(PRUNE_CRITICAL)" = "YES" ] ; then \
		rm -rf gentoo/usr/lib/python*/test ; \
		rm -rf gentoo/usr/share/gtk-doc ; \
		rm -rf gentoo/var/db/pkg ; \
		rm -rf gentoo/usr/lib/perl* ; \
	fi
	rsync -ax gentoo/ loop/
	loop/sbin/grub --device-map=device-map --no-floppy --batch < grub.shell
	umount loop
	umount gentoo
	sleep 3
	rmdir loop
	rm -rf gentoo
	qemu-nbd -d /dev/nbd0
	touch image

$(QCOW_IMAGE): $(RAW_IMAGE) image
	qemu-img convert -f raw -O qcow2 -c $(RAW_IMAGE) $(QCOW_IMAGE)

qcow: $(QCOW_IMAGE)


$(VMDK_IMAGE): $(RAW_IMAGE) image
	qemu-img convert -f raw -O vmdk $(RAW_IMAGE) $(VMDK_IMAGE)

vmdk: $(VMDK_IMAGE)

.PHONY: kernel qcow vmdk clean

clean:
	umount $(CHROOT)/usr/portage $(CHROOT)/var/tmp $(CHROOT)/dev $(CHROOT)/proc || true
	rm -f mounts compile_options base_system portage
	rm -f parted grub stage3 software preproot sysconfig systools image kernel partitions device-map
	rm -rf loop
	rm -rf gentoo
	rm -rf $(CHROOT)

realclean: clean
	rm -f $(RAW_IMAGE) $(QCOW_IMAGE) $(VMDK_IMAGE)
