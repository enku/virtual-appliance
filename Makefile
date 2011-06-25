CHROOT=./vabuild
APPLIANCE = base
HOSTNAME = $(APPLIANCE)
RAW_IMAGE = $(HOSTNAME).img
QCOW_IMAGE = $(HOSTNAME).qcow
VMDK_IMAGE = $(HOSTNAME).vmdk
XVA_IMAGE = $(HOSTNAME).xva
STAGE4_TARBALL = stage4/$(HOSTNAME)-stage4.tar.bz2
KERNEL_CONFIG = kernel.config
VIRTIO = NO
TIMEZONE = UTC
DISK_SIZE = 6.0G
SWAP_SIZE = 30
SWAP_FILE = $(CHROOT)/.swap
ARCH = amd64
MAKEOPTS = -j4
PRUNE_CRITICAL = NO
REMOVE_PORTAGE_TREE = YES
ENABLE_SSHD = NO
CHANGE_PASSWORD = YES
HEADLESS = NO
EXTERNAL_KERNEL = NO
UDEV = YES
SOFTWARE = 1
PKGLIST = 0
ACCEPT_KEYWORDS = amd64
DASH = NO

M4 = m4
EMERGE = /usr/bin/emerge
M4_DEFS = -D HOSTNAME=$(HOSTNAME)
M4C = $(M4) $(M4_DEFS)
NBD_DEV = /dev/nbd0
USEPKG = --usepkg --binpkg-respect-use=y
RSYNC_MIRROR = rsync://rsync.gtlib.gatech.edu/gentoo/
KERNEL = gentoo-sources
PACKAGE_FILES = $(APPLIANCE)/package.*
WORLD = $(APPLIANCE)/world
CRITICAL = $(APPLIANCE)/critical

-include $(APPLIANCE)/$(APPLIANCE).cfg
-include $(profile).cfg

inroot := chroot $(CHROOT)

ifneq ($(SOFTWARE),0)
	software_extra = build-software
endif

ifneq ($(PKGDIR),)
	MOUNT_PKGDIR = mkdir -p $(CHROOT)/var/portage/packages; \
		mount -o bind "$(PKGDIR)" $(CHROOT)/var/portage/packages
	UMOUNT_PKGDIR = umount $(CHROOT)/var/portage/packages
	ADD_PKGDIR = echo PKGDIR="/var/portage/packages" >> $(CHROOT)/etc/make.conf
endif

ifeq ($(PRUNE_CRITICAL),YES)
	COPY_ARGS = --exclude-from=rsync-excludes \
		--exclude-from=rsync-excludes-critical
	UNMERGE_CRITICAL = $(inroot) $(EMERGE) -C `cat $(CRITICAL)`
else
	COPY_ARGS = --exclude-from=rsync-excludes
endif

ifeq ($(CHANGE_PASSWORD),YES)
	ifdef ROOT_PASSWORD
		change_password = $(inroot) usermod -p '$(ROOT_PASSWORD)' root
	else
		change_password = $(inroot) passwd -d root; $(inroot) passwd -e root
	endif
endif

ifeq ($(REMOVE_PORTAGE_TREE),YES)
	COPY_ARGS += --exclude=usr/portage
endif

ifeq ($(VIRTIO),YES)
	VIRTIO_FSTAB = sed -i 's/sda/vda/' $(CHROOT)/etc/fstab
	VIRTIO_GRUB = sed -i 's/sda/vda/' $(CHROOT)/boot/grub/grub.conf
endif

ifeq ($(HEADLESS),YES)
	HEADLESS_INITTAB = sed -ri 's/^(c[0-9]:)/\#\1/' $(CHROOT)/etc/inittab
	HEADLESS_GRUB = sed -i -f grub-headless.sed $(CHROOT)/boot/grub/grub.conf
endif

ifeq ($(ENABLE_SSHD),YES)
	enable_sshd = $(inroot) /sbin/rc-update add sshd default
endif

gcc_config = $(inroot) gcc-config 1

export APPLIANCE ACCEPT_KEYWORDS CHROOT EMERGE HEADLESS M4 M4C inroot
export HOSTNAME MAKEOPTS PRUNE_CRITICAL TIMEZONE USEPKG WORLD OVERLAY

unexport PKGDIR ARCH NBD_DEV 

all: image

$(RAW_IMAGE):
	qemu-img create -f raw $(RAW_IMAGE) $(DISK_SIZE)

partitions: $(RAW_IMAGE)
	parted -s $(RAW_IMAGE) mklabel msdos
	parted -s $(RAW_IMAGE) mkpart primary ext2 0 $(DISK_SIZE)
	parted -s $(RAW_IMAGE) set 1 boot on

	qemu-nbd -c $(NBD_DEV) $(RAW_IMAGE)
	sleep 3
	mkfs.ext4 -O sparse_super,^has_journal -L "$(APPLIANCE)"_root $(NBD_DEV)p1
	touch partitions

mounts: stage3
	mkdir -p $(CHROOT)
	if [ ! -e mounts ] ; then \
		mount -t proc none $(CHROOT)/proc; \
		mount -o bind /dev $(CHROOT)/dev; \
		mount -o bind /var/tmp $(CHROOT)/var/tmp; \
	fi
	touch mounts

sync_portage:
	rsync --no-motd -L $(RSYNC_MIRROR)/snapshots/portage-latest.tar.bz2 portage-latest.tar.bz2
	touch sync_portage

portage: sync_portage stage3
	tar xjf portage-latest.tar.bz2 -C $(CHROOT)/usr
	$(MOUNT_PKGDIR)
	touch portage

preproot: stage3 mounts portage
	cp -L /etc/resolv.conf $(CHROOT)/etc/
	$(inroot) sed -i 's/root:.*/root::9797:0:::::/' /etc/shadow
	touch preproot

stage3: 
	mkdir -p $(CHROOT)
	if test -e "$(STAGE4_TARBALL)"; \
	then tar xjpf "$(STAGE4_TARBALL)" -C $(CHROOT); \
	else rsync --no-motd $(RSYNC_MIRROR)/releases/`echo $(ARCH)|sed 's/i.86/x86/'`/autobuilds/latest-stage3.txt .; \
	rsync --no-motd $(RSYNC_MIRROR)/releases/`echo $(ARCH)|sed 's/i.86/x86/'`/autobuilds/`tail -n 1 latest-stage3.txt` stage3-$(ARCH)-latest.tar.bz2; \
	tar xjpf stage3-$(ARCH)-latest.tar.bz2 -C $(CHROOT); \
	rm -f $(CHROOT)/dev/null ; \
	mknod --mode=600 $(CHROOT)/dev/console c 5 1; \
	mknod --mode=666 $(CHROOT)/dev/null c 1 3; \
	mknod --mode=666 $(CHROOT)/dev/zero c 1 5; \
	$(inroot) ln -nsf /etc/init.d/udev /etc/runlevels/sysinit/udev; \
	fi
	touch stage3

compile_options: portage make.conf locale.gen $(PACKAGE_FILES)
	cp make.conf $(CHROOT)/etc/make.conf
	$(ADD_PKGDIR)
	echo ACCEPT_KEYWORDS=$(ACCEPT_KEYWORDS) >> $(CHROOT)/etc/make.conf
	cp locale.gen $(CHROOT)/etc/locale.gen
	$(inroot) locale-gen
	mkdir -p $(CHROOT)/etc/portage
	for f in $(PACKAGE_FILES) ; do \
		cp $$f $(CHROOT)/etc/portage/ ; \
	done
	touch compile_options

base_system: mounts compile_options
	touch base_system

kernel: base_system $(KERNEL_CONFIG)
	$(inroot) cp /usr/share/zoneinfo/$(TIMEZONE) /etc/localtime
	echo $(TIMEZONE) > "$(CHROOT)"/etc/timezone
ifneq ($(EXTERNAL_KERNEL),YES)
	$(inroot) $(EMERGE) -n $(USEPKG) sys-kernel/$(KERNEL)
	cp $(KERNEL_CONFIG) $(CHROOT)/usr/src/linux/.config
	$(gcc_config)
	$(inroot) make $(MAKEOPTS) -C /usr/src/linux oldconfig
	$(inroot) make $(MAKEOPTS) -C /usr/src/linux
	$(inroot) make $(MAKEOPTS) -C /usr/src/linux modules_install
	$(inroot) make $(MAKEOPTS) -C /usr/src/linux install
	cd $(CHROOT)/boot ; \
		k=`/bin/ls -1 --sort=time vmlinuz-*|head -n 1` ; \
		ln -nsf $$k vmlinuz
endif
	touch kernel

$(SWAP_FILE): preproot
	dd if=/dev/zero of=$(SWAP_FILE) bs=1M count=$(SWAP_SIZE)
	/sbin/mkswap $(SWAP_FILE)

$(CHROOT)/etc/fstab: fstab preproot
	cp fstab $(CHROOT)/etc/fstab

$(CHROOT)/etc/conf.d/hostname: preproot
	echo hostname=\"$(HOSTNAME)\" > $(CHROOT)/etc/conf.d/hostname

sysconfig: preproot $(SWAP_FILE) $(CHROOT)/etc/fstab $(CHROOT)/etc/conf.d/hostname
	@echo $(VIRTIO)
	$(VIRTIO_FSTAB)
ifeq ($(VIRTIO),YES)
	sed -i 's:clock_hctosys="YES":clock_hctosys="NO":g' "$(CHROOT)/etc/conf.d/hwclock"
	sed -i '/^rc_sys=/d' "$(CHROOT)/etc/rc.conf"
	echo 'rc_sys=""' >> "$(CHROOT)/etc/rc.conf"
endif
	sed -i 's/^#s0:/s0:/' $(CHROOT)/etc/inittab
	$(HEADLESS_INITTAB)
	echo 'modules="dhclient"' > $(CHROOT)/etc/conf.d/net
	echo 'config_eth0="dhcp"' >> $(CHROOT)/etc/conf.d/net
	echo 'dhcp_eth0="release"' >> $(CHROOT)/etc/conf.d/net
	$(inroot) ln -nsf net.lo /etc/init.d/net.eth0
	$(inroot) ln -nsf /etc/init.d/net.eth0 /etc/runlevels/default/net.eth0
	$(inroot) rm -f /etc/runlevels/boot/consolefont
	touch sysconfig

systools: sysconfig compile_options
	$(inroot) $(EMERGE) -n $(USEPKG) app-admin/syslog-ng
	$(inroot) /sbin/rc-update add syslog-ng default
	$(inroot) $(EMERGE) -n $(USEPKG) sys-power/acpid
	$(inroot) /sbin/rc-update add acpid default
	$(inroot) $(EMERGE) -n $(USEPKG) net-misc/dhcp
ifeq ($(DASH),YES)
	if ! test -e "$(STAGE4_TARBALL)"; \
	then $(inroot) $(EMERGE) -n $(USEPKG) app-shells/dash; \
	echo /bin/dash >> $(CHROOT)/etc/shells; \
	$(inroot) chsh -s /bin/dash root; \
	fi
endif
	$(inroot) ln -sf dash /bin/sh
	touch systools

grub: stage3 grub.conf kernel partitions
ifneq ($(EXTERNAL_KERNEL),YES)
	$(inroot) $(EMERGE) -nN $(USEPKG) sys-boot/grub
	cp grub.conf $(CHROOT)/boot/grub/grub.conf
	$(VIRTIO_GRUB)
	$(HEADLESS_GRUB)
endif
	touch grub

build-software: systools issue etc-update.conf $(CRITICAL) $(WORLD)
	$(MAKE) -C $(APPLIANCE) preinstall
	cp etc-update.conf $(CHROOT)/etc/
	
	# some packages, like, tar need xz-utils to unpack, but it not part of
	# the stage3 so may not be installed yet
	$(inroot) $(EMERGE) -1n $(USEPKG) app-arch/xz-utils
	
	$(inroot) $(EMERGE) $(USEPKG) --update --newuse --deep `cat $(WORLD)`
	$(gcc_config)
	
	# Need gentoolkit to run revdep-rebuild
	$(inroot) $(EMERGE) -1n $(USEPKG) app-portage/gentoolkit
	$(inroot) revdep-rebuild -i
	
	cp issue $(CHROOT)/etc/issue
	$(gcc_config)
	$(inroot) $(EMERGE) $(USEPKG) --update --newuse --deep world
	# Per bug #357009
	$(inroot) eselect python update --ignore 3.*
	$(inroot) $(EMERGE) --depclean --with-bdeps=n
	$(gcc_config)
	$(inroot) etc-update
	$(MAKE) -C $(APPLIANCE) postinstall
	$(enable_sshd)
	$(change_password)
	$(UNMERGE_CRITICAL)

software: stage3 $(software_extra)
ifneq ($(PKGLIST),0)
	(cd "$(CHROOT)"/var/db/pkg ; /bin/ls -1d */*) > $(APPLIANCE)-packages.lst
endif
	touch software

device-map: $(RAW_IMAGE)
	echo '(hd0) ' $(RAW_IMAGE) > device-map

image: software device-map grub.shell grub dev.tar.bz2
	mkdir -p loop
	mount -o noatime $(NBD_DEV)p1 loop
	mkdir -p gentoo
	mount -o bind $(CHROOT) gentoo
	rsync -ax $(COPY_ARGS) gentoo/ loop/
ifneq ($(EXTERNAL_KERNEL),YES)
	loop/sbin/grub --device-map=device-map --no-floppy --batch < grub.shell
endif
ifeq ($(UDEV),NO)
	tar jxf dev.tar.bz2 -C loop/dev
	rm -f loop/dev/vda*
	/bin/mknod loop/dev/vda b 254 0
	/bin/mknod loop/dev/vda1 b 254 1
	/bin/mknod loop/dev/vda2 b 254 2
	chown root:disk loop/dev/vda*
	rm -f loop/etc/runlevels/sysinit/udev
endif
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

$(XVA_IMAGE): $(RAW_IMAGE) image
	xva.py --disk=$(RAW_IMAGE) --is-hvm --memory=256 --vcpus=1 --name=$(APPLIANCE) \
		--filename=$(XVA_IMAGE)

xva: $(XVA_IMAGE)


$(VMDK_IMAGE): $(RAW_IMAGE) image
	qemu-img convert -f raw -O vmdk $(RAW_IMAGE) $(VMDK_IMAGE)

vmdk: $(VMDK_IMAGE)

$(STAGE4_TARBALL): software kernel rsync-excludes rsync-excludes-critical
	mkdir -p stage4
	mkdir -p gentoo
	mount -o bind $(CHROOT) gentoo
	tar -jScf "$(STAGE4_TARBALL)".tmp --numeric-owner $(COPY_ARGS) -C gentoo --one-file-system .
	umount gentoo
	rmdir gentoo
	mv "$(STAGE4_TARBALL)".tmp "$(STAGE4_TARBALL)"

stage4: $(STAGE4_TARBALL)


umount: 
	$(UMOUNT_PKGDIR)
	umount  $(CHROOT)/var/tmp
	umount  $(CHROOT)/dev
	umount  $(CHROOT)/proc
	touch umount

remove_checkpoints:
	rm -f mounts compile_options base_system portage sync_portage
	rm -f parted kernel grub stage3 software preproot sysconfig systools image partitions device-map

clean: umount remove_checkpoints
	rm -f umount
	rm -rf loop gentoo
	rm -rf gentoo
	rm -rf $(CHROOT)

realclean: clean
	${RM} $(RAW_IMAGE) $(QCOW_IMAGE) $(VMDK_IMAGE)

distclean: 
	rm -f *.qcow *.img *.vmdk
	rm -f latest-stage3.txt stage3-*-latest.tar.bz2
	rm -f *-stage4.tar.bz2
	rm -f portage-latest.tar.bz2

.PHONY: qcow vmdk clean realclean distclean remove_checkpoints stage4 build-software
	
