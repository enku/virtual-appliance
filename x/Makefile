xdm_files = $(wildcard xdm/*)

preinstall:

postinstall: $(xdm_files)
	cp xdm/* "$(CHROOT)"/etc/X11/xdm
	ln -sf /etc/init.d/xdm "$(CHROOT)/etc/runlevels/default/xdm"

clean:

