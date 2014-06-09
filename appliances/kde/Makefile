
preinstall:

postinstall: kdmrc kdm.start Xaccess knotifyrc
	cp kdmrc Xaccess "$(CHROOT)"/usr/share/config/kdm
	mkdir -p "$(CHROOT)"/etc/skel/.kde4/share/config
	cp knotifyrc "$(CHROOT)"/etc/skel/.kde4/share/config/knotifyrc
	cp kdm.start "$(CHROOT)"/etc/local.d/kdm.start
	$(inroot) ln -nsf /etc/init.d/dbus /etc/runlevels/default/dbus

clean:


