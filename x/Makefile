xdm_files = $(wildcard xdm/*)

preinstall:

postinstall: $(xdm_files)
	cp xdm/* "$(CHROOT)"/etc/X11/xdm
	chroot "$(CHROOT)" rc-update add xdm default;

clean:

