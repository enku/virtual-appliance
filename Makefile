CHROOT=./vabuild
APPLIANCE = base
HOSTNAME = $(APPLIANCE)
RAW_IMAGE = $(HOSTNAME).img
QCOW_IMAGE = $(HOSTNAME).qcow
VMDK_IMAGE = $(HOSTNAME).vmdk
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
ACCEPT_KEYWORDS = amd64

M4 = m4
EMERGE = /usr/bin/emerge
M4_DEFS = -D HOSTNAME=$(HOSTNAME)
M4C = $(M4) $(M4_DEFS)
NBD_DEV = /dev/nbd0
USEPKG = --usepkg --binpkg-respect-use=y
RSYNC_MIRROR = rsync://mirrors.rit.edu/gentoo/
KERNEL = gentoo-sources
PACKAGE_FILES = $(APPLIANCE)/package.*
WORLD = $(APPLIANCE)/world
CRITICAL = $(APPLIANCE)/critical

-include $(profile).cfg

inroot := chroot $(CHROOT)

ifneq ($(PKGDIR),)
	MOUNT_PKGDIR = mkdir -p $(CHROOT)/var/portage/packages; \
		mount -o bind "$(PKGDIR)" $(CHROOT)/var/portage/packages
	UMOUNT_PKGDIR = umount $(CHROOT)/var/portage/packages
	ADD_PKGDIR = echo PKGDIR="/var/portage/packages" >> $(CHROOT)/etc/make.conf
endif

ifeq ($(PRUNE_CRITICAL),YES)
	COPY_LOOP = rsync -ax --exclude-from=rsync-excludes \
		--exclude-from=rsync-excludes-critical gentoo/ loop/
	UNMERGE_CRITICAL = $(inroot) $(EMERGE) -C `cat $(CRITICAL)`
else
	COPY_LOOP = rsync -ax --exclude-from=rsync-excludes gentoo/ loop/
endif

ifeq ($(CHANGE_PASSWORD),YES)
	ifdef ROOT_PASSWORD
		change_password = $(inroot) usermod -p '$(ROOT_PASSWORD)' root
	else
		change_password = $(inroot) passwd -d root; $(inroot) passwd -e root
	endif
endif

ifeq ($(REMOVE_PORTAGE_TREE),YES)
	COPY_LOOP += --exclude=usr/portage
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
	enable_sshd = $(inroot) rc-update add sshd default
endif

gcc_config = $(inroot) gcc-config 1

export APPLIANCE ACCEPT_KEYWORDS CHROOT EMERGE HEADLESS M4 M4C 
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
	touch preproot

stage3: 
	mkdir -p $(CHROOT)
	rsync --no-motd $(RSYNC_MIRROR)/releases/`echo $(ARCH)|sed 's/i.86/x86/'`/autobuilds/latest-stage3.txt .
	rsync --no-motd $(RSYNC_MIRROR)/releases/`echo $(ARCH)|sed 's/i.86/x86/'`/autobuilds/`tail -n 1 latest-stage3.txt` stage3-$(ARCH)-latest.tar.bz2
	tar xjpf stage3-$(ARCH)-latest.tar.bz2 -C $(CHROOT)
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
	echo HOSTNAME=$(HOSTNAME) > $(CHROOT)/etc/conf.d/hostname

$(CHROOT)/etc/conf.d/clock: preproot
	sed -i 's/^#TIMEZONE=.*/TIMEZONE="$(TIMEZONE)"/' $(CHROOT)/etc/conf.d/clock

sysconfig: preproot $(SWAP_FILE) $(CHROOT)/etc/fstab $(CHROOT)/etc/conf.d/hostname $(CHROOT)/etc/conf.d/clock
	@echo $(VIRTIO)
	$(VIRTIO_FSTAB)
	sed -i 's/^#s0:/s0:/' $(CHROOT)/etc/inittab
	$(HEADLESS_INITTAB)
	echo 'config_eth0=( "dhcp" )' > $(CHROOT)/etc/conf.d/net
	echo 'dhcp_eth0="release"' >> $(CHROOT)/etc/conf.d/net
	$(inroot) ln -nsf net.lo /etc/init.d/net.eth0
	$(inroot) rc-update add net.eth0 default
	$(inroot) rc-update del consolefont boot
	touch sysconfig

systools: sysconfig compile_options
	$(inroot) $(EMERGE) -n $(USEPKG) app-admin/syslog-ng
	$(inroot) rc-update add syslog-ng default
	$(inroot) $(EMERGE) -n $(USEPKG) sys-power/acpid
	$(inroot) rc-update add acpid default
	$(inroot) $(EMERGE) -n $(USEPKG) net-misc/dhcpcd
	touch systools

grub: systools grub.conf kernel
ifneq ($(EXTERNAL_KERNEL),YES)
	$(inroot) $(EMERGE) -nN $(USEPKG) sys-boot/grub
	cp grub.conf $(CHROOT)/boot/grub/grub.conf
	$(VIRTIO_GRUB)
	$(HEADLESS_GRUB)
endif
	touch grub

software: systools issue etc-update.conf $(CRITICAL) $(WORLD)
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
	$(inroot) $(EMERGE) --depclean --with-bdeps=n
	$(gcc_config)
	$(inroot) etc-update
	$(MAKE) -C $(APPLIANCE) postinstall
	$(enable_sshd)
	$(change_password)
	$(UNMERGE_CRITICAL)
	touch software

device-map: $(RAW_IMAGE)
	echo '(hd0) ' $(RAW_IMAGE) > device-map

image: $(RAW_IMAGE) grub partitions device-map grub.shell systools software
	mkdir -p loop
	mount -o noatime $(NBD_DEV)p1 loop
	mkdir -p gentoo
	mount -o bind $(CHROOT) gentoo
	$(COPY_LOOP)
ifneq ($(EXTERNAL_KERNEL),YES)
	loop/sbin/grub --device-map=device-map --no-floppy --batch < grub.shell
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


$(VMDK_IMAGE): $(RAW_IMAGE) image
	qemu-img convert -f raw -O vmdk $(RAW_IMAGE) $(VMDK_IMAGE)

vmdk: $(VMDK_IMAGE)

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
	rm -f portage-latest.tar.bz2

.PHONY: qcow vmdk clean realclean distclean remove_checkpoints
