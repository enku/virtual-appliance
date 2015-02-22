xdm_files = $(wildcard xdm/*)

preinstall:

postinstall: $(xdm_files)
	cp $(xdm_files) "$(CHROOT)"/etc/X11/xdm
	echo "XSESSION=Xfce4" > "$(CHROOT)"/etc/env.d/99local
	$(inroot) env-update
	$(inroot) systemctl enable xdm.service

clean:


