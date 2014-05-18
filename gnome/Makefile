
preinstall: custom.conf dhclient.conf
	mkdir -p "$(CHROOT)"/etc/dhcp
	cp dhclient.conf "$(CHROOT)"/etc/dhcp/dhclient.conf
	mkdir -p "$(CHROOT)"/etc/gdm
	cp custom.conf "$(CHROOT)"/etc/gdm/custom.conf


postinstall: 
	$(inroot) systemctl enable NetworkManager.service
	$(inroot) systemctl enable gdm.service
	$(inroot) systemctl enable avahi-daemon.service
	$(inroot) ln -nsf /usr/lib/systemd/systemd /sbin/init

clean:

