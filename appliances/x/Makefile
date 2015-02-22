xdm_files = $(wildcard xdm/*)

preinstall:

postinstall: $(xdm_files)
	cp xdm/* "$(CHROOT)"/etc/X11/xdm
	$(inroot) systemctl enable xdm

clean:

