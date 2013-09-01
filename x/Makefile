xdm_files = $(wildcard xdm/*)

preinstall:

postinstall: $(xdm_files) xdm.start
	cp xdm/* "$(CHROOT)"/etc/X11/xdm
	cp xdm.start "$(CHROOT)"/etc/local.d

clean:

