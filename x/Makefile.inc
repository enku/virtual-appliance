preinstall =
postinstall = cp "$(APPLIANCE)"/xdm/* "$(CHROOT)"/etc/X11/xdm;             \
	chroot "$(CHROOT)" rc-update add xdm default;
