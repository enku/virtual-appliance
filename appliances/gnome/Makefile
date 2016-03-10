
preinstall: custom.conf
	mkdir -p "$(CHROOT)"/etc/gdm
	cp custom.conf "$(CHROOT)"/etc/gdm/custom.conf
	# bug 575388
	$(inroot) mkdir -p /etc/portage/env/net-libs
	echo 'CFLAGS="-O2 -pipe"' > $(CHROOT)/etc/portage/env/net-libs/webkit-gtk
	echo 'CXXFLAGS="$$CFLAGS"' >> $(CHROOT)/etc/portage/env/net-libs/webkit-gtk


postinstall: 
	$(inroot) systemctl enable gdm.service
	$(inroot) systemctl enable avahi-daemon.service

clean:

