preinstall =
postinstall = cp "$(APPLIANCE)"/xdm/* "$(CHROOT)"/etc/X11/xdm;             \
	echo "XSESSION=Xfce4" > "$(CHROOT)"/etc/env.d/99local;                 \
	chroot "$(CHROOT)" env-update;                                         \
	chroot "$(CHROOT)" rc-update add xdm default;


