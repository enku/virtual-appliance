CHROOT = $(PWD)/vabuild
APPLIANCE ?= base
HOSTNAME = $(APPLIANCE)
RAW_IMAGE = $(HOSTNAME).img
QCOW_IMAGE = $(HOSTNAME).qcow
VMDK_IMAGE = $(HOSTNAME).vmdk
XVA_IMAGE = $(HOSTNAME).xva
LST_FILE = $(HOSTNAME)-packages.lst
STAGE4_TARBALL = stage4/$(HOSTNAME)-stage4.tar.xz
KERNEL_CONFIG = kernel.config
VIRTIO = NO
TIMEZONE = UTC
DISK_SIZE = 6.0G
SWAP_SIZE = 30
SWAP_FILE = $(CHROOT)/.swap
ARCH = amd64
MAKEOPTS = -j10 -l10
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
EMERGE = /usr/bin/emerge --jobs=4
M4_DEFS = -D HOSTNAME=$(HOSTNAME)
M4C = $(M4) $(M4_DEFS)
NBD_DEV = /dev/nbd0
USEPKG = --usepkg --binpkg-respect-use=y
RSYNC_MIRROR = rsync://rsync.gtlib.gatech.edu/gentoo/
EMERGE_RSYNC = NO
KERNEL = gentoo-sources
PACKAGE_FILES = $(wildcard $(APPLIANCE)/package.*)
WORLD = $(APPLIANCE)/world
EXTRA_WORLD =
CRITICAL = $(APPLIANCE)/critical
DOWNLOAD_DIR = .downloads

# Allow appliance to override variables
-include $(APPLIANCE)/$(APPLIANCE).cfg

# Allow user to override variables
-include $(profile).cfg

inroot := chroot $(CHROOT)
ifeq ($(ARCH),x86)
	inroot := linux32 $(inroot)
endif

stage4-exists := $(wildcard $(STAGE4_TARBALL))
software-deps := stage3

ifneq ($(SOFTWARE),0)
	software-deps += build-software
endif


ifeq ($(PRUNE_CRITICAL),YES)
	COPY_ARGS = --exclude-from=rsync-excludes \
		--exclude-from=rsync-excludes-critical
else
	COPY_ARGS = --exclude-from=rsync-excludes
endif

ifeq ($(REMOVE_PORTAGE_TREE),YES)
	COPY_ARGS += --exclude=usr/portage
endif

ifeq ($(CHANGE_PASSWORD),YES)
	ifdef ROOT_PASSWORD
		change_password = $(inroot) usermod -p '$(ROOT_PASSWORD)' root
	else
		change_password = $(inroot) passwd -d root; $(inroot) passwd -e root
	endif
endif

gcc_config = $(inroot) gcc-config 1

export APPLIANCE ACCEPT_KEYWORDS CHROOT EMERGE HEADLESS M4 M4C inroot
export HOSTNAME MAKEOPTS PRUNE_CRITICAL TIMEZONE USEPKG WORLD OVERLAY

unexport PKGDIR ARCH NBD_DEV 

all: image

$(RAW_IMAGE):
	qemu-img create -f raw $(RAW_IMAGE) $(DISK_SIZE)

partitions: $(RAW_IMAGE)
	@./echo Creating partition layout
	parted -s $(RAW_IMAGE) mklabel gpt
	parted -s $(RAW_IMAGE) mkpart primary 1 $(DISK_SIZE)
	parted -s $(RAW_IMAGE) set 1 boot on

	qemu-nbd -c $(NBD_DEV) "`realpath $(RAW_IMAGE)`"
	sleep 3
	mkfs.ext4 -t small -C 21504 -O sparse_super,^has_journal -L "$(APPLIANCE)"_root $(NBD_DEV)p1
	touch partitions

mounts: stage3
	@./echo Creating chroot in $(CHROOT)
	mkdir -p $(CHROOT)
	if [ ! -e mounts ] ; then \
		mount -t proc none $(CHROOT)/proc; \
		mount -o bind /dev $(CHROOT)/dev; \
		mount -o bind /var/tmp $(CHROOT)/var/tmp; \
	fi
	touch mounts

sync_portage:
	@./echo Grabbing latest portage snapshot
	mkdir -p $(DOWNLOAD_DIR)
	rsync --no-motd -L $(RSYNC_MIRROR)/snapshots/portage-latest.tar.bz2 $(DOWNLOAD_DIR)/portage-latest.tar.bz2
	touch sync_portage

portage: sync_portage stage3
	@./echo Unpacking portage snapshot
	rm -rf $(CHROOT)/usr/portage
	tar xjf $(DOWNLOAD_DIR)/portage-latest.tar.bz2 -C $(CHROOT)/usr
ifeq ($(EMERGE_RSYNC),YES)
	@./echo Syncing portage tree
	$(inroot) emerge --sync --quiet
endif
ifdef PKGDIR
	mkdir -p $(CHROOT)/var/portage/packages
	mount -o bind "$(PKGDIR)" $(CHROOT)/var/portage/packages
endif
	touch portage

preproot: stage3 mounts portage
	cp -L /etc/resolv.conf $(CHROOT)/etc/
	$(inroot) sed -i 's/root:.*/root::9797:0:::::/' /etc/shadow
	touch preproot

stage3: 
	mkdir -p $(CHROOT)
ifdef stage4-exists
	@./echo Using stage4 tarball: $(STAGE4_TARBALL)
	tar xapf "$(STAGE4_TARBALL)" -C $(CHROOT)
else
	mkdir -p $(DOWNLOAD_DIR)
	rsync --no-motd $(RSYNC_MIRROR)/releases/`echo $(ARCH)|sed 's/i.86/x86/'`/autobuilds/latest-stage3.txt $(DOWNLOAD_DIR)
	rsync --no-motd $(RSYNC_MIRROR)/releases/`echo $(ARCH)|sed 's/i.86/x86/'`/autobuilds/`grep $(ARCH) $(DOWNLOAD_DIR)/latest-stage3.txt|grep -v multilib` $(DOWNLOAD_DIR)/stage3-$(ARCH)-latest.tar.bz2
	@./echo Using stage3 tarball
	tar xjpf $(DOWNLOAD_DIR)/stage3-$(ARCH)-latest.tar.bz2 -C $(CHROOT)
endif
	touch stage3

compile_options: portage make.conf.$(ARCH) locale.gen $(PACKAGE_FILES)
	cp make.conf.$(ARCH) $(CHROOT)/etc/portage/make.conf
ifdef PKGDIR
	echo PKGDIR="/var/portage/packages" >> $(CHROOT)/etc/portage/make.conf
endif
	echo ACCEPT_KEYWORDS=$(ACCEPT_KEYWORDS) >> $(CHROOT)/etc/portage/make.conf
	[ -f "$(APPLIANCE)/make.conf" ] && cat "$(APPLIANCE)/make.conf" >> $(CHROOT)/etc/portage/make.conf
	cp locale.gen $(CHROOT)/etc/locale.gen
	$(inroot) locale-gen
	mkdir -p $(CHROOT)/etc/portage
ifdef PACKAGE_FILES
	cp $(PACKAGE_FILES) $(CHROOT)/etc/portage/
endif
	touch compile_options

base_system: mounts compile_options
	touch base_system

kernel: base_system $(KERNEL_CONFIG) kernel.sh
	$(inroot) cp /usr/share/zoneinfo/$(TIMEZONE) /etc/localtime
	echo $(TIMEZONE) > "$(CHROOT)"/etc/timezone
ifneq ($(EXTERNAL_KERNEL),YES)
	@./echo Configuring kernel
	cp $(KERNEL_CONFIG) $(CHROOT)/root/kernel.config
	cp kernel.sh $(CHROOT)/tmp/kernel.sh
	KERNEL=$(KERNEL) EMERGE="$(EMERGE)" USEPKG="$(USEPKG)" MAKEOPTS="$(MAKEOPTS)" \
	   $(inroot) /bin/sh /tmp/kernel.sh
	rm -f $(CHROOT)/tmp/kernel.sh
endif
	touch kernel

$(SWAP_FILE): preproot
	@./echo Creating swap file: $(SWAP_FILE)
	dd if=/dev/zero of=$(SWAP_FILE) bs=1M count=$(SWAP_SIZE)
	/sbin/mkswap $(SWAP_FILE)

$(CHROOT)/etc/fstab: fstab preproot
	cp fstab $(CHROOT)/etc/fstab

$(CHROOT)/etc/conf.d/hostname: preproot
	echo hostname=\"$(HOSTNAME)\" > $(CHROOT)/etc/conf.d/hostname

sysconfig: preproot acpi.start $(SWAP_FILE) $(CHROOT)/etc/fstab $(CHROOT)/etc/conf.d/hostname
	@echo $(VIRTIO)
ifeq ($(VIRTIO),YES)
	sed -i 's/sda/vda/' $(CHROOT)/etc/fstab
	sed -i 's:clock_hctosys="YES":clock_hctosys="NO":g' "$(CHROOT)/etc/conf.d/hwclock"
	sed -i '/^rc_sys=/d' "$(CHROOT)/etc/rc.conf"
	echo 'rc_sys=""' >> "$(CHROOT)/etc/rc.conf"
endif
ifeq ($(HEADLESS),YES)
	sed -i 's/^#s0:/s0:/' $(CHROOT)/etc/inittab
	sed -ri 's/^(c[0-9]:)/\#\1/' $(CHROOT)/etc/inittab
	rm -f $(CHROOT)/etc/runlevels/boot/termencoding
	rm -f $(CHROOT)/etc/runlevels/boot/keymaps
endif
	echo 'modules="dhclient"' > $(CHROOT)/etc/conf.d/net
	echo 'config_eth0="udhcpc"' >> $(CHROOT)/etc/conf.d/net
	echo 'dhcp_eth0="release"' >> $(CHROOT)/etc/conf.d/net
	$(inroot) ln -nsf net.lo /etc/init.d/net.eth0
	$(inroot) ln -nsf /etc/init.d/net.eth0 /etc/runlevels/default/net.eth0
	$(inroot) rm -f /etc/runlevels/boot/consolefont
	cp -a acpi.start $(CHROOT)/etc/local.d
	touch sysconfig

systools: sysconfig compile_options
	@./echo Installing standard system tools
	$(inroot) $(EMERGE) -n $(USEPKG) app-admin/metalog
	$(inroot) /sbin/rc-update add metalog default
ifeq ($(DASH),YES)
	if ! test -e "$(STAGE4_TARBALL)";  \
	then $(inroot) $(EMERGE) -n $(USEPKG) app-shells/dash; \
	echo /bin/dash >> $(CHROOT)/etc/shells; \
	$(inroot) chsh -s /bin/sh root; \
	fi
	$(inroot) ln -sf dash /bin/sh
endif
	touch systools

grub: stage3 grub.conf kernel partitions
ifneq ($(EXTERNAL_KERNEL),YES)
	@./echo Installing Grub
	$(inroot) $(EMERGE) -nN $(USEPKG) sys-boot/grub-static
	cp grub.conf $(CHROOT)/boot/grub/grub.conf
ifeq ($(VIRTIO),YES)
	sed -i 's/sda/vda/' $(CHROOT)/boot/grub/grub.conf
endif
ifeq ($(HEADLESS),YES)
	sed -i -f grub-headless.sed $(CHROOT)/boot/grub/grub.conf
endif
endif
	touch grub

build-software: systools issue etc-update.conf $(CRITICAL) $(WORLD)
	@./echo Building $(APPLIANCE)-specific software
	$(MAKE) -C $(APPLIANCE) preinstall
	cp etc-update.conf $(CHROOT)/etc/
	
	# some packages, like, tar need xz-utils to unpack, but it not part of
	# the stage3 so may not be installed yet
	#$(inroot) $(EMERGE) -1n $(USEPKG) app-arch/xz-utils
	
	if test `stat -c "%s" $(WORLD)` -ne 0 ; then \
		$(inroot) $(EMERGE) $(USEPKG) --update --newuse --deep `cat $(WORLD)` $(EXTRA_WORLD); \
		else \
		true; \
	fi
	$(gcc_config)
	
	@./echo Running revdep-rebuild
	# Need gentoolkit to run revdep-rebuild
	$(inroot) $(EMERGE) -1n $(USEPKG) app-portage/gentoolkit
	$(inroot) revdep-rebuild -i
	
	cp issue $(CHROOT)/etc/issue
	$(gcc_config)
	$(inroot) $(EMERGE) $(USEPKG) --update --newuse --deep world
	$(inroot) $(EMERGE) --depclean --with-bdeps=n
	$(gcc_config)
	EDITOR=/usr/bin/nano $(inroot) etc-update
	$(MAKE) -C $(APPLIANCE) postinstall
ifeq ($(ENABLE_SSHD),YES)
	$(inroot) /sbin/rc-update add sshd default
endif
	$(change_password)
ifeq ($(PRUNE_CRITICAL),YES)
	$(inroot) $(EMERGE) -C `cat $(CRITICAL)`
ifeq ($(DASH),YES)
	$(inroot) $(EMERGE) -c app-shells/bash
endif
endif

software: $(software-deps)
ifneq ($(PKGLIST),0)
	echo \# > $(LST_FILE)
	echo \# Gentoo Virtual Appliance \"$(APPLIANCE)\" package list >> $(LST_FILE)
	echo \# Generated `date -u` >> $(LST_FILE)
	echo \# >> $(LST_FILE)
	(cd "$(CHROOT)"/var/db/pkg ; /bin/ls -1d */*) >> $(LST_FILE)
endif
	touch software

device-map: $(RAW_IMAGE)
	echo '(hd0) ' $(RAW_IMAGE) > device-map

image: kernel software device-map grub.shell grub dev.tar.bz2 motd.sh
	@./echo Installing files to $(RAW_IMAGE) 
	mkdir -p loop
	mount -o noatime $(NBD_DEV)p1 loop
	mkdir -p gentoo
	mount -o bind $(CHROOT) gentoo
	rsync -ax $(COPY_ARGS) gentoo/ loop/
ifeq ($(PRUNE_CRITICAL),YES)
	rsync -ax gentoo/usr/include/python* loop/usr/include/
endif
	./motd.sh $(EXTERNAL_KERNEL) $(VIRTIO) $(DISK_SIZE) $(SWAP_SIZE) $(UDEV) $(DASH) $(ARCH) > loop/etc/motd
ifneq ($(EXTERNAL_KERNEL),YES)
	loop/sbin/grub --device-map=device-map --no-floppy --batch < grub.shell
endif
ifeq ($(UDEV),NO)
	tar jxf dev.tar.bz2 -C loop/dev
	rm -f loop/etc/runlevels/sysinit/udev
else
	ln -sf /etc/init.d/udev loop/etc/runlevels/sysinit/udev
endif
	umount gentoo
	rmdir gentoo
	umount loop
	sleep 3
	rmdir loop
	e2fsck -fyD $(NBD_DEV)p1 || true
	qemu-nbd -d $(NBD_DEV)
	touch image

$(QCOW_IMAGE): $(RAW_IMAGE) image
	@./echo Creating $(QCOW_IMAGE)
	qemu-img convert -f raw -O qcow2 -c $(RAW_IMAGE) $(QCOW_IMAGE)

qcow: $(QCOW_IMAGE)

$(XVA_IMAGE): $(RAW_IMAGE) image
	@./echo Creating $(XVA_IMAGE)
	xva.py --disk=$(RAW_IMAGE) --is-hvm --memory=256 --vcpus=1 --name=$(APPLIANCE) \
		--filename=$(XVA_IMAGE)

xva: $(XVA_IMAGE)


$(VMDK_IMAGE): $(RAW_IMAGE) image
	@./echo Creating $(VMDK_IMAGE)
	qemu-img convert -f raw -O vmdk $(RAW_IMAGE) $(VMDK_IMAGE)

vmdk: $(VMDK_IMAGE)

$(STAGE4_TARBALL): software kernel rsync-excludes rsync-excludes-critical
	@./echo Creating stage4 tarball: $(STAGE4_TARBALL)
	mkdir -p stage4
	mkdir -p gentoo
	mount -o bind $(CHROOT) gentoo
	tar -aScf "$(STAGE4_TARBALL).tmp.xz" --numeric-owner $(COPY_ARGS) -C gentoo --one-file-system .
	umount gentoo
	rmdir gentoo
	mv "$(STAGE4_TARBALL).tmp.xz" "$(STAGE4_TARBALL)"

stage4: $(STAGE4_TARBALL)


umount: 
	@./echo Attempting to unmount chroot mounts
ifdef PKGDIR
	umount $(CHROOT)/var/portage/packages
endif
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

.PHONY: qcow vmdk clean realclean distclean remove_checkpoints stage4 build-software
