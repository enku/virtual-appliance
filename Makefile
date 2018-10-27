APPLIANCE ?= base
VABUILDER_OUTPUT := $(CURDIR)
CHROOT = $(VABUILDER_OUTPUT)/build/$(APPLIANCE)
VA_PKGDIR = $(VABUILDER_OUTPUT)/packages
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
STAGE3 = $(CHROOT)/var/tmp/stage3
COMPILE_OPTIONS = $(CHROOT)/var/tmp/compile_options
SOFTWARE = $(CHROOT)/var/tmp/software
KERNEL = $(CHROOT)/var/tmp/kernel
GRUB = $(CHROOT)/var/tmp/grub
PREPROOT = $(CHROOT)/var/tmp/preproot
SYSTOOLS = $(CHROOT)/var/tmp/systools
STAGE4_TARBALL = $(VABUILDER_OUTPUT)/images/$(APPLIANCE).tar.xz
VIRTIO = NO
TIMEZONE = UTC
DISK_SIZE = 6.0G
SWAP_SIZE = 30
SWAP_FILE = $(CHROOT)/.swap
VA_ARCH = amd64
KERNEL_CONFIG = configs/kernel.config.$(VA_ARCH)
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
KERNEL_PKG = gentoo-sources
PACKAGE_FILES = $(wildcard appliances/$(APPLIANCE)/package.*)
WORLD = appliances/$(APPLIANCE)/world
EXTRA_WORLD =

# Allow appliance to override variables
-include appliances/$(APPLIANCE)/$(APPLIANCE).cfg

# Allow user to override variables
-include $(profile).cfg

ifneq ($(profile),)
	container = $(profile)-$(APPLIANCE)-build
else
	container = $(APPLIANCE)-build
endif

PATH := $(CURDIR)/scripts:$(PATH)

export PATH CHROOT container PORTAGE_DIR VA_PKGDIR DISTDIR VA_ARCH

inroot := systemd-nspawn --quiet \
	--directory=$(CHROOT) \
	--machine=$(container) \
	--bind=$(PORTAGE_DIR):/usr/portage \
	--bind=$(VA_PKGDIR):/usr/portage/packages \
	--bind=$(DISTDIR):/usr/portage/distfiles 

ifeq ($(VA_ARCH),x86)
	inroot := linux32 $(inroot)
endif

stage4-exists := $(wildcard $(STAGE4_TARBALL))

COPY_ARGS = --exclude-from=configs/rsync-excludes

ifeq ($(CHANGE_PASSWORD),YES)
	ifdef ROOT_PASSWORD
		change_password = RUN usermod --password '$(ROOT_PASSWORD)' root
	else
		change_password = RUN passwd --delete root
	endif
endif

gcc_config = $(inroot) gcc-config 1

export APPLIANCE ACCEPT_KEYWORDS CHROOT EMERGE HEADLESS M4 M4C inroot
export HOSTNAME MAKEOPTS TIMEZONE USEPKG WORLD 
export USEPKG RSYNC_MIRROR

all: stage4

image: $(RAW_IMAGE)

sync_portage: $(PORTAGE_DIR)
	@scripts/echo Grabbing latest portage
	git -C $(PORTAGE_DIR) pull
	touch $(PORTAGE_DIR)

$(PORTAGE_DIR):
	@scripts/echo Grabbing the portage tree
	git clone --depth=1 git://github.com/gentoo/gentoo.git $(PORTAGE_DIR)

$(PREPROOT): $(STAGE3) $(PORTAGE_DIR) configs/fstab
	mkdir -p $(VA_PKGDIR) $(DISTDIR)
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
	COPY -L /etc/resolv.conf /etc/resolv.conf
	touch $(PREPROOT)

stage3-$(VA_ARCH).tar.bz2:
	@scripts/echo You do not have a stage3 tarball. Consider \"make sync_stage3\"
	@exit 1

sync_stage3:
	./scripts/fetch-stage3 --specialty=systemd --outfile=stage3-$(VA_ARCH).tar.bz2 $(VA_ARCH)


$(STAGE3): stage3-$(VA_ARCH).tar.bz2
	mkdir -p $(CHROOT)
ifdef stage4-exists
	@scripts/echo Using stage4 tarball: `basename $(STAGE4_TARBALL)`
	tar xpf "$(STAGE4_TARBALL)" -C $(CHROOT)
else
	@scripts/echo Using stage3 tarball
	tar xpf stage3-$(VA_ARCH).tar.bz2 -C $(CHROOT)
endif
	rm -f $(CHROOT)/etc/localtime
	touch $(STAGE3)

$(COMPILE_OPTIONS): $(STAGE3) $(PORTAGE_DIR) configs/make.conf.$(VA_ARCH) configs/locale.gen $(PACKAGE_FILES)
	COPY configs/make.conf.$(VA_ARCH) /etc/portage/make.conf
	echo ACCEPT_KEYWORDS=$(ACCEPT_KEYWORDS) >> $(CHROOT)/etc/portage/make.conf
	-[ -f "appliances/$(APPLIANCE)/make.conf" ] && cat "appliances/$(APPLIANCE)/make.conf" >> $(CHROOT)/etc/portage/make.conf
	COPY configs/locale.gen /etc/locale.gen
	RUN locale-gen
	for f in $(PACKAGE_FILES); do \
		base=`basename $$f` ; \
		mkdir -p $(CHROOT)/etc/portage/$$base; \
		COPY $$f /etc/portage/$$base/virtual-appliance-$$base; \
	done
	touch $(COMPILE_OPTIONS)

$(KERNEL): $(COMPILE_OPTIONS) $(KERNEL_CONFIG) scripts/build-kernel
ifneq ($(EXTERNAL_KERNEL),YES)
	@scripts/echo Configuring kernel
	COPY $(KERNEL_CONFIG) /root/kernel.config
	COPY scripts/build-kernel /root/build-kernel
	RUN --setenv=KERNEL=$(KERNEL_PKG) \
	    --setenv=EMERGE="$(EMERGE)" \
	    --setenv=USEPKG="$(USEPKG)" \
	    --setenv=MAKEOPTS="$(MAKEOPTS)" \
	    /root/build-kernel
	rm -f $(CHROOT)/root/build-kernel
endif
	touch $(KERNEL)

$(SYSTOOLS): $(PREPROOT) $(COMPILE_OPTIONS)
	@scripts/echo Installing standard system tools
	systemd-firstboot \
		--root=$(CHROOT) \
		--setup-machine-id \
		--timezone=$(TIMEZONE) \
		--hostname=$(HOSTNAME) \
		--root-password=
	RUN eselect locale set $(LOCALE)
ifeq ($(DASH),YES)
	if ! test -e "$(STAGE4_TARBALL)";  \
	then RUN $(EMERGE) --noreplace $(USEPKG) app-shells/dash; \
	echo /bin/dash >> $(CHROOT)/etc/shells; \
	RUN chsh -s /bin/sh root; \
	fi
	RUN ln -sf dash /bin/sh
endif
	touch $(SYSTOOLS)

$(GRUB): $(PREPROOT) configs/grub.cfg $(KERNEL) scripts/grub-headless.sed
ifneq ($(EXTERNAL_KERNEL),YES)
	@scripts/echo Installing Grub
	RUN $(EMERGE) -nN $(USEPKG) sys-boot/grub
	mkdir -p $(CHROOT)/boot/grub
	COPY configs/grub.cfg /boot/grub/grub.cfg
ifeq ($(VIRTIO),YES)
	sed -i 's/sda/vda/' $(CHROOT)/boot/grub/grub.cfg
endif
ifeq ($(HEADLESS),YES)
	sed -i -f scripts/grub-headless.sed $(CHROOT)/boot/grub/grub.cfg
endif
endif
	ln -nsf /run/systemd/resolve/resolv.conf $(CHROOT)/etc/resolv.conf
	touch $(GRUB)


$(SOFTWARE): $(STAGE3) $(SYSTOOLS) configs/eth.network configs/issue $(WORLD) $(PROFILE)
	@scripts/echo Building $(APPLIANCE)-specific software
	$(MAKE) -C appliances/$(APPLIANCE) preinstall
	
	COPY $(WORLD) /var/lib/portage/world
	RUN $(EMERGE) $(USEPKG) --update --newuse --deep @system
	
	@scripts/echo Running @preserved-rebuild
	RUN $(EMERGE) --usepkg=n @preserved-rebuild
	
	COPY configs/issue /etc/issue
	RUN $(EMERGE) $(USEPKG) --update --newuse --deep @world $(grub_package)
	RUN $(EMERGE) --depclean --with-bdeps=n
	RUN --setenv EDITOR=/usr/bin/nano etc-update
	COPY configs/eth.network /etc/systemd/network/eth.network
	RUN systemctl enable systemd-networkd.service
	RUN systemctl enable systemd-resolved.service
ifeq ($(ENABLE_SSHD),YES)
	RUN systemctl enable sshd.service
endif
ifeq ($(DASH),YES)
	RUN $(EMERGE) --depclean app-shells/bash
endif
	$(MAKE) -C appliances/$(APPLIANCE) postinstall
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
	parted -s $(RAW_IMAGE).tmp mklabel msdos
	parted -s $(RAW_IMAGE).tmp mkpart primary 1 $(DISK_SIZE)
	parted -s $(RAW_IMAGE).tmp set 1 boot on
	sync
	losetup --show --find --partscan $(RAW_IMAGE).tmp > partitions
	mkfs.ext4 -O sparse_super,^has_journal -L "$(APPLIANCE)"_root -m 0 `cat partitions`p1
	mkdir $(CHROOT)
	mount -o noatime `cat partitions`p1 $(CHROOT)
	tar -xf $(STAGE4_TARBALL) --numeric-owner $(COPY_ARGS) -C $(CHROOT)
	scripts/motd.sh $(EXTERNAL_KERNEL) $(VIRTIO) $(DISK_SIZE) $(SWAP_SIZE) $(DASH) $(VA_ARCH) > $(CHROOT)/etc/motd
ifneq ($(EXTERNAL_KERNEL),YES)
	echo '(hd0) ' `cat partitions` > device-map
	$(CHROOT)/usr/sbin/grub-install --no-floppy --grub-mkdevicemap=device-map --directory=$(CHROOT)/usr/lib/grub/i386-pc --boot-directory=$(CHROOT)/boot `cat partitions`
endif
	COPY device-map /boot/grub/device.map
	RUN --bind=/dev grub-mkconfig
	RUN --bind=/dev grub-mkconfig -o /boot/grub/grub.cfg
	umount $(CHROOT)/boot
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

$(STAGE4_TARBALL): $(PORTAGE_DIR) stage3-$(VA_ARCH).tar.bz2 appliances/$(APPLIANCE) configs/rsync-excludes
	$(MAKE) $(STAGE3)
	$(MAKE) $(PREPROOT)
	$(MAKE) $(SOFTWARE)
	$(MAKE) $(KERNEL)
	$(MAKE) $(GRUB)
	@scripts/echo Creating stage4 tarball: `basename $(STAGE4_TARBALL)`
	$(change_password)
	mkdir -p $(IMAGES)
	tar -acf "$(STAGE4_TARBALL).tmp.xz" --numeric-owner $(COPY_ARGS) -C $(CHROOT) --one-file-system .
	mv "$(STAGE4_TARBALL).tmp.xz" "$(STAGE4_TARBALL)"
	$(MAKE) clean

stage4: $(STAGE4_TARBALL)


eclean: $(COMPILE_OPTIONS)
	RUN $(EMERGE) $(USEPKG) --oneshot --noreplace app-portage/gentoolkit
	RUN eclean-pkg
	RUN eclean-dist
	RUN $(EMERGE) --depclean app-portage/gentoolkit
	$(MAKE) clean


clean:
	rm -f partitions device-map $(IMAGES)/*.tmp
	rm -rf --one-file-system -- $(CHROOT)

realclean: clean
	${RM} $(RAW_IMAGE) $(QCOW_IMAGE) $(VMDK_IMAGE)

distclean: 
	rm -f -- *.qcow *.img *.vmdk
	rm -f stage3-*.tar.bz2
	rm -f portage-snapshot.tar.bz2

appliance-list:
	@scripts/echo 'Available appliances:'
	@/bin/ls -1 appliances


checksums:
	@scripts/echo 'Calculating checksums'
	$(RM) $(CHECKSUMS)
	cd $(IMAGES) && sha256sum --binary * > $(CHECKSUMS).tmp
	mv $(CHECKSUMS).tmp $(CHECKSUMS)

shell: $(PREPROOT)
	@scripts/echo 'Entering interactive shell for the $(APPLIANCE) build.'
	@scripts/echo 'Type "exit" or "^D" to leave'
	@scripts/echo
	@RUN
	@rm -f $(CHROOT)/root/.bash_history

help:
	@scripts/echo 'Help targets (this is not a comprehensive list)'
	@echo
	@echo 'sync_portage             - Download the latest portage snapshot'
	@echo 'sync_stage3              - Download the latest stage3 tarball'
	@echo 'stage4                   - Build a stage4 tarball'
	@echo 'clean                    - Unmount chroot and clean directory'
	@echo 'eclean                   - Clean outdated packages and distfiles'
	@echo 'realclean                - Clean and remove image files'
	@echo 'shell                    - Enter a shell in the build environment'
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
	@echo 'VA_ARCH=                 - Architecture to build for (x86 or amd64)'
	@echo 'VIRTIO=YES               - Configure the stage2/image to use virtio'
	@echo 'EXTERNAL_KERNEL=YES      - Do not build a kernel in the image'
	@echo 'HEADLESS=YES             - Build a headless (serial console) image.'
	@echo 'ENABLE_SSHD=YES          - Enable sshd to start automatically in the image'
	@echo
	@scripts/echo 'Example'
	@echo 'make APPLIANCE=mongodb HEADLESS=YES VIRTIO=YES stage4 qcow clean'

.PHONY: qcow vmdk clean realclean distclean stage4 image stage4 help appliance-list eclean sync_portage sync_stage3 checksums
