xdm_files = $(wildcard xdm/*)

preinstall:

postinstall: $(xdm_files)
	cp $(xdm_files) "$(CHROOT)"/etc/X11/xdm
	echo "XSESSION=Xfce4" > "$(CHROOT)"/etc/env.d/99local
	chroot "$(CHROOT)" env-update
	echo /usr/bin/xdm >> "$(CHROOT)"/etc/conf.d/local.start

clean:


