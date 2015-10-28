
preinstall: custom.conf
	mkdir -p "$(CHROOT)"/etc/gdm
	cp custom.conf "$(CHROOT)"/etc/gdm/custom.conf


postinstall: 
	$(inroot) systemctl enable gdm.service
	$(inroot) systemctl enable avahi-daemon.service

clean:

