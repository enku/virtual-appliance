
preinstall:
	echo 'USE="$$USE qt3support xcomposite opengl"' >>  "$(CHROOT)"/etc/portage/make.conf

postinstall: kdmrc kdm.start Xaccess knotifyrc
	cp kdmrc Xaccess "$(CHROOT)"/usr/share/config/kdm
	mkdir -p "$(CHROOT)"/etc/skel/.kde4/share/config
	cp knotifyrc "$(CHROOT)"/etc/skel/.kde4/share/config/knotifyrc
	cp kdm.start "$(CHROOT)"/etc/local.d/kdm.start
	chroot "$(CHROOT)" ln -nsf /etc/init.d/dbus /etc/runlevels/default/dbus

clean:


