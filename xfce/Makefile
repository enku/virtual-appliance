xdm_files = $(wildcard xdm/*)

preinstall:

postinstall: $(xdm_files)
	cp $(xdm_files) "$(CHROOT)"/etc/X11/xdm
	echo "XSESSION=Xfce4" > "$(CHROOT)"/etc/env.d/99local
	chroot "$(CHROOT)" env-update
	chroot "$(CHROOT)" rc-update add xdm default

clean:


