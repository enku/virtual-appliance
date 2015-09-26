APPLIANCE ?= base
VABUILDER_OUTPUT := $(CURDIR)
CHROOT = $(VABUILDER_OUTPUT)/build/$(APPLIANCE)
PKGDIR = $(VABUILDER_OUTPUT)/packages
DISTDIR = $(CURDIR)/distfiles
PORTAGE_DIR = $(CURDIR)/portage
HOSTNAME = $(APPLIANCE)
IMAGES = $(VABUILDER_OUTPUT)/images
RAW_IMAGE = $(IMAGES)/$(APPLIANCE).img
QCOW_IMAGE = $(IMAGES)/$(APPLIANCE).qcow
VMDK_IMAGE = $(IMAGES)/$(APPLIANCE).vmdk
XVA_IMAGE = $(IMAGES)/$(APPLIANCE).xva
LST_FILE = $(IMAGES)/$(APPLIANCE)-packages.lst
CHECKSUMS = $(IMAGES)/SHA256SUMS
STAGE3 = $(CHROOT)/tmp/stage3
COMPILE_OPTIONS = $(CHROOT)/tmp/compile_options
SOFTWARE = $(CHROOT)/tmp/software
KERNEL = $(CHROOT)/tmp/kernel
GRUB = $(CHROOT)/tmp/grub
PREPROOT = $(CHROOT)/tmp/preproot
SYSTOOLS = $(CHROOT)/tmp/systools
STAGE4_TARBALL = $(VABUILDER_OUTPUT)/images/$(APPLIANCE).tar.xz
VIRTIO = NO
TIMEZONE = UTC
DISK_SIZE = 6.0G
SWAP_SIZE = 30
SWAP_FILE = $(CHROOT)/.swap
ARCH = amd64
KERNEL_CONFIG = configs/kernel.config.$(ARCH)
MAKEOPTS = -j5 -l5.64
ENABLE_SSHD = NO
CHANGE_PASSWORD = YES
HEADLESS = NO
EXTERNAL_KERNEL = NO
PKGLIST = 0
ACCEPT_KEYWORDS = amd64
DASH = NO
LOCALE ?= en_US.utf8

M4 = m4
EMERGE = /usr/bin/emerge --jobs=4
M4_DEFS = -D HOSTNAME=$(HOSTNAME)
M4C = $(M4) $(M4_DEFS)
USEPKG = --usepkg --binpkg-respect-use=y
RSYNC_MIRROR = rsync://rsync.gtlib.gatech.edu/gentoo/
EMERGE_RSYNC = NO
KERNEL_PKG = gentoo-sources
PACKAGE_FILES = $(wildcard appliances/$(APPLIANCE)/package.*)
WORLD = appliances/$(APPLIANCE)/world
EXTRA_WORLD =

# Allow appliance to override variables
-include appliance/$(APPLIANCE)/$(APPLIANCE).cfg

# Allow user to override variables
-include $(profile).cfg

ifneq ($(profile),)
	container = $(profile)-$(APPLIANCE)-build
else
	container = $(APPLIANCE)-build
endif


inroot := systemd-nspawn --quiet \
	--directory=$(CHROOT) \
	--machine=$(container) \
	--bind=$(PORTAGE_DIR)/portage:/usr/portage \
	--bind=$(PKGDIR):/usr/portage/packages \
	--bind=$(DISTDIR):/usr/portage/distfiles 

ifeq ($(ARCH),x86)
	inroot := linux32 $(inroot)
endif

stage4-exists := $(wildcard $(STAGE4_TARBALL))

COPY_ARGS = --exclude-from=configs/rsync-excludes

ifeq ($(CHANGE_PASSWORD),YES)
	ifdef ROOT_PASSWORD
		change_password = $(inroot) usermod -p '$(ROOT_PASSWORD)' root
	else
		change_password = $(inroot) passwd --delete --expire root
	endif
endif

gcc_config = $(inroot) gcc-config 1

export APPLIANCE ACCEPT_KEYWORDS CHROOT EMERGE HEADLESS M4 M4C inroot
export HOSTNAME MAKEOPTS TIMEZONE USEPKG WORLD 
export USEPKG RSYNC_MIRROR

unexport PKGDIR ARCH 

all: stage4

image: $(RAW_IMAGE)

portage-snapshot.tar.bz2:
	@scripts/echo You do not have a portage snapshot. Consider \"make sync_portage\"
	@exit 1


sync_portage:
	@scripts/echo Grabbing latest portage snapshot
	rsync --no-motd -L $(RSYNC_MIRROR)/snapshots/portage-latest.tar.bz2 portage-snapshot.tar.bz2
	touch portage-snapshot.tar.bz2


$(PORTAGE_DIR): portage-snapshot.tar.bz2
	@scripts/echo Unpacking portage snapshot
	rm -rf $(PORTAGE_DIR)
	mkdir $(PORTAGE_DIR)
	tar xf portage-snapshot.tar.bz2 -C $(PORTAGE_DIR)
ifeq ($(EMERGE_RSYNC),YES)
	@scripts/echo Syncing portage tree
	$(inroot) emerge --sync --quiet
endif

$(PREPROOT): $(STAGE3) $(PORTAGE_DIR) configs/fstab
	mkdir -p $(PKGDIR) $(DISTDIR)
	#$(inroot) sed -i 's/root:.*/root::9797:0:::::/' /etc/shadow
	cp configs/fstab $(CHROOT)/etc/fstab
ifeq ($(VIRTIO),YES)
	sed -i 's/sda/vda/' $(CHROOT)/etc/fstab
endif
ifneq ($(SWAP_SIZE),0)
	@scripts/echo Creating swap file: `basename $(SWAP_FILE)`
	dd if=/dev/zero of=$(SWAP_FILE) bs=1M count=$(SWAP_SIZE)
	/sbin/mkswap $(SWAP_FILE)
else
	sed -i '/swap/d' $(CHROOT)/etc/fstab
endif
	rm -f $(CHROOT)/etc/resolv.conf
	cp -L /etc/resolv.conf $(CHROOT)/etc/resolv.conf
	touch $(PREPROOT)

stage3-$(ARCH)-latest.tar.bz2:
	@scripts/echo You do not have a stage3 tarball. Consider \"make sync_stage3\"
	@exit 1

sync_stage3:
	./scripts/sync-stage3.sh $(ARCH)


$(STAGE3): stage3-$(ARCH)-latest.tar.bz2
	mkdir -p $(CHROOT)
ifdef stage4-exists
	@scripts/echo Using stage4 tarball: `basename $(STAGE4_TARBALL)`
	tar xpf "$(STAGE4_TARBALL)" -C $(CHROOT)
else
	@scripts/echo Using stage3 tarball
	tar xpf stage3-$(ARCH)-latest.tar.bz2 -C $(CHROOT)
endif
	rm -f $(CHROOT)/etc/localtime
	touch $(STAGE3)

$(COMPILE_OPTIONS): $(STAGE3) $(PORTAGE_DIR) configs/make.conf.$(ARCH) configs/locale.gen $(PACKAGE_FILES)
	cp configs/make.conf.$(ARCH) $(CHROOT)/etc/portage/make.conf
	echo ACCEPT_KEYWORDS=$(ACCEPT_KEYWORDS) >> $(CHROOT)/etc/portage/make.conf
	-[ -f "appliances/$(APPLIANCE)/make.conf" ] && cat "appliances/$(APPLIANCE)/make.conf" >> $(CHROOT)/etc/portage/make.conf
	$(inroot) eselect profile set 1
	cp configs/locale.gen $(CHROOT)/etc/locale.gen
	$(inroot) locale-gen
	for f in $(PACKAGE_FILES); do \
		base=`basename $$f` ; \
		mkdir -p $(CHROOT)/etc/portage/$$base; \
		cp $$f $(CHROOT)/etc/portage/$$base/virtual-appliance-$$base; \
	done
	touch $(COMPILE_OPTIONS)

$(KERNEL): $(COMPILE_OPTIONS) $(KERNEL_CONFIG) scripts/kernel.sh
ifneq ($(EXTERNAL_KERNEL),YES)
	@scripts/echo Configuring kernel
	cp $(KERNEL_CONFIG) $(CHROOT)/root/kernel.config
	cp scripts/kernel.sh $(CHROOT)/root/kernel.sh
	$(inroot) --setenv=KERNEL=$(KERNEL_PKG) \
		      --setenv=EMERGE="$(EMERGE)" \
	          --setenv=USEPKG="$(USEPKG)" \
			  --setenv=MAKEOPTS="$(MAKEOPTS)" \
	          /bin/sh /root/kernel.sh
	rm -f $(CHROOT)/root/kernel.sh
endif
	touch $(KERNEL)

$(SYSTOOLS): $(PREPROOT) $(COMPILE_OPTIONS)
	@scripts/echo Installing standard system tools
	-$(inroot) $(EMERGE) --unmerge sys-fs/udev
	$(inroot) $(EMERGE) $(USEPKG) --noreplace --oneshot sys-apps/systemd
	$(inroot) systemd-firstboot \
		--timezone=$(TIMEZONE) \
		--hostname=$(HOSTNAME) \
		--root-password=
	$(inroot) eselect locale set $(LOCALE)
ifeq ($(DASH),YES)
	if ! test -e "$(STAGE4_TARBALL)";  \
	then $(inroot) $(EMERGE) --noreplace $(USEPKG) app-shells/dash; \
	echo /bin/dash >> $(CHROOT)/etc/shells; \
	$(inroot) chsh -s /bin/sh root; \
	fi
	$(inroot) ln -sf dash /bin/sh
endif
	touch $(SYSTOOLS)

$(GRUB): $(PREPROOT) configs/grub.conf $(KERNEL) scripts/grub-headless.sed
ifneq ($(EXTERNAL_KERNEL),YES)
	@scripts/echo Installing Grub
	$(inroot) $(EMERGE) -nN $(USEPKG) sys-boot/grub-static
	cp configs/grub.conf $(CHROOT)/boot/grub/grub.conf
ifeq ($(VIRTIO),YES)
	sed -i 's/sda/vda/' $(CHROOT)/boot/grub/grub.conf
endif
ifeq ($(HEADLESS),YES)
	sed -i -f scripts/grub-headless.sed $(CHROOT)/boot/grub/grub.conf
endif
endif
	$(inroot) ln -nsf /run/systemd/resolve/resolv.conf /etc/resolv.conf
	touch $(GRUB)


$(SOFTWARE): $(STAGE3) $(SYSTOOLS) configs/eth.network configs/issue $(WORLD)
	@scripts/echo Building $(APPLIANCE)-specific software
	$(MAKE) -C appliances/$(APPLIANCE) preinstall
	
	cp $(WORLD) $(CHROOT)/tmp/world
	$(inroot) xargs -a/tmp/world -d'\n' -r $(EMERGE) $(USEPKG) --update --newuse --deep 
	-$(gcc_config)
	
	@scripts/echo Running @preserved-rebuild
	$(inroot) $(EMERGE) --usepkg=n @preserved-rebuild
	
	cp configs/issue $(CHROOT)/etc/issue
	-$(gcc_config)
	$(inroot) $(EMERGE) $(USEPKG) --update --newuse --deep world
	$(inroot) $(EMERGE) --depclean --with-bdeps=n
	-$(gcc_config)
	$(inroot) --setenv EDITOR=/usr/bin/nano etc-update
	$(MAKE) -C appliances/$(APPLIANCE) postinstall
	cp configs/eth.network $(CHROOT)/etc/systemd/network/eth.network
	$(inroot) systemctl enable systemd-networkd.service
	$(inroot) systemctl enable systemd-resolved.service
ifeq ($(ENABLE_SSHD),YES)
	$(inroot) systemctl enable sshd.service
endif
	$(change_password)
ifeq ($(DASH),YES)
	$(inroot) $(EMERGE) --depclean app-shells/bash
endif
ifneq ($(PKGLIST),0)
	echo \# > $(LST_FILE)
	echo \# Gentoo Virtual Appliance \"$(APPLIANCE)\" package list >> $(LST_FILE)
	echo \# Generated `date -u` >> $(LST_FILE)
	echo \# >> $(LST_FILE)
	(cd "$(CHROOT)"/var/db/pkg ; /bin/ls -1d */* | grep -v '^virtual/') >> $(LST_FILE)
endif
	touch $(SOFTWARE)


$(RAW_IMAGE): $(STAGE4_TARBALL) scripts/grub.shell scripts/motd.sh
	@scripts/echo Installing files to `basename $(RAW_IMAGE)`
	qemu-img create -f raw $(RAW_IMAGE).tmp $(DISK_SIZE)
	parted -s $(RAW_IMAGE).tmp mklabel gpt
	parted -s $(RAW_IMAGE).tmp mkpart primary 1 $(DISK_SIZE)
	parted -s $(RAW_IMAGE).tmp set 1 boot on
	sync
	losetup --show --find --partscan $(RAW_IMAGE).tmp > partitions
	mkfs.ext4 -O sparse_super,^has_journal -L "$(APPLIANCE)"_root -m 0 `cat partitions`p1
	mkdir $(CHROOT)
	mount -o noatime `cat partitions`p1 $(CHROOT)
	tar -xf $(STAGE4_TARBALL) --numeric-owner $(COPY_ARGS) -C $(CHROOT)
	scripts/motd.sh $(EXTERNAL_KERNEL) $(VIRTIO) $(DISK_SIZE) $(SWAP_SIZE) $(DASH) $(ARCH) > $(CHROOT)/etc/motd
ifneq ($(EXTERNAL_KERNEL),YES)
	echo '(hd0) ' $(RAW_IMAGE).tmp > device-map
	$(CHROOT)/sbin/grub --device-map=device-map --no-floppy --batch < scripts/grub.shell
endif
	umount $(CHROOT)
	rmdir $(CHROOT)
	sync
	losetup --detach `cat partitions`
	rm -f partitions device-map
	mv $(RAW_IMAGE).tmp $(RAW_IMAGE)

$(QCOW_IMAGE): $(RAW_IMAGE)
	@scripts/echo Creating `basename $(QCOW_IMAGE)`
	qemu-img convert -f raw -O qcow2 -c $(RAW_IMAGE) $(QCOW_IMAGE).tmp
	mv $(QCOW_IMAGE).tmp $(QCOW_IMAGE)

qcow: $(QCOW_IMAGE)

$(XVA_IMAGE): $(RAW_IMAGE)
	@scripts/echo Creating `basename $(XVA_IMAGE)`
	xva.py --disk=$(RAW_IMAGE) --is-hvm --memory=256 --vcpus=1 --name=$(APPLIANCE) \
		--filename=$(XVA_IMAGE).tmp
	mv $(XVA_IMAGE).tmp $(XVA_IMAGE)

xva: $(XVA_IMAGE)


$(VMDK_IMAGE): $(RAW_IMAGE)
	@scripts/echo Creating `basename $(VMDK_IMAGE)`
	qemu-img convert -f raw -O vmdk $(RAW_IMAGE) $(VMDK_IMAGE).tmp
	mv $(VMDK_IMAGE).tmp $(VMDK_IMAGE)

vmdk: $(VMDK_IMAGE)

$(STAGE4_TARBALL): $(PORTAGE_DIR) stage3-$(ARCH)-latest.tar.bz2 appliances/$(APPLIANCE) configs/rsync-excludes
	$(MAKE) $(STAGE3)
	$(MAKE) $(PREPROOT)
	$(MAKE) $(SOFTWARE)
	$(MAKE) $(KERNEL)
	$(MAKE) $(GRUB)
	@scripts/echo Creating stage4 tarball: `basename $(STAGE4_TARBALL)`
	mkdir -p $(IMAGES)
	tar -acf "$(STAGE4_TARBALL).tmp.xz" --numeric-owner $(COPY_ARGS) -C $(CHROOT) --one-file-system .
	mv "$(STAGE4_TARBALL).tmp.xz" "$(STAGE4_TARBALL)"
	$(MAKE) clean

stage4: $(STAGE4_TARBALL)


eclean: $(COMPILE_OPTIONS)
	$(inroot) $(EMERGE) $(USEPKG) --oneshot --noreplace app-portage/gentoolkit
	$(inroot) eclean-pkg
	$(inroot) eclean-dist
	$(inroot) $(EMERGE) --depclean app-portage/gentoolkit
	$(MAKE) clean


clean:
	rm -f partitions device-map $(IMAGES)/*.tmp
	rm -rf --one-file-system -- $(CHROOT)

realclean: clean
	${RM} $(RAW_IMAGE) $(QCOW_IMAGE) $(VMDK_IMAGE)

distclean: 
	rm -f -- *.qcow *.img *.vmdk
	rm -f latest-stage3.txt stage3-*-latest.tar.bz2
	rm -f portage-snapshot.tar.bz2

appliance-list:
	@scripts/echo 'Available appliances:'
	@/bin/ls -1 appliances


checksums:
	$(RM) $(CHECKSUMS)
	cd $(IMAGES) && sha256sum --binary * > $(CHECKSUMS).tmp
	mv $(CHECKSUMS).tmp $(CHECKSUMS)

help:
	@scripts/echo 'Help targets (this is not a comprehensive list)'
	@echo
	@echo 'sync_portage             - Download the latest portage snapshot'
	@echo 'sync_stage3              - Download the latest stage3 tarball'
	@echo 'stage4                   - Build a stage4 tarball'
	@echo 'clean                    - Unmount chroot and clean directory'
	@echo 'eclean                   - Clean outdated packages and distfiles'
	@echo 'realclean                - Clean and remove image files'
	@scripts/echo 'Images'
	@echo 'image                    - Build a raw VM image from stage4'
	@echo 'qcow                     - Build a qcow VM image from a raw image'
	@echo 'vmdk                     - Build a vmdk image from a raw image'
	@echo 'xva                      - Build an xva image from a raw image'
	@echo 'appliance-list           - List built-in appliances'
	@echo 'help                     - Show this help'
	@scripts/echo 'Variables'
	@echo 'APPLIANCE=               - The appliance to build'
	@echo 'HOSTNAME=                - Hostname to give appliance'
	@echo 'TIMEZONE=                - Timezone to set for the appliance'
	@echo 'CHROOT=                  - The directory to build the chroot'
	@echo 'DISK_SIZE=               - Size of the disk image'
	@echo 'SWAP_SIZE=               - Size of the swap file'
	@echo 'ARCH=                    - Architecture to build for (x86 or amd64)'
	@echo 'VIRTIO=YES               - Configure the stage2/image to use virtio'
	@echo 'EXTERNAL_KERNEL=YES      - Do not build a kernel in the image'
	@echo 'HEADLESS=YES             - Build a headless (serial console) image.'
	@echo 'ENABLE_SSHD=YES          - Enable sshd to start automatically in the image'
	@echo
	@scripts/echo 'Example'
	@echo 'make APPLIANCE=mongodb HEADLESS=YES VIRTIO=YES stage4 qcow clean'

.PHONY: qcow vmdk clean realclean distclean stage4 image stage4 help appliance-list eclean sync_portage sync_stage3 checksums
