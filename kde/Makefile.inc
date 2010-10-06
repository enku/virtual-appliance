preinstall = echo 'USE="$$USE qt3support xcomposite opengl"' >>          \
	"$(CHROOT)"/etc/make.conf;

postinstall = cp "$(APPLIANCE)"/kdmrc "$(APPLIANCE)"/Xaccess               \
	"$(CHROOT)"/usr/share/config/kdm;                                      \
	chroot "$(CHROOT)" rc-update add dbus default;                         \
	if [ -e "$(CHROOT)"/etc/conf.d/xdm ] ; then                            \
    	sed -i 's/^DISPLAYMANAGER=.*/DISPLAYMANAGER="kdm"/'                \
		"$(CHROOT)"/etc/conf.d/xdm;                                        \
		chroot "$(CHROOT)" rc-update add xdm default;                      \
	else                                                                   \
		echo "/usr/bin/kdm -daemon" >> "$(CHROOT)"/etc/conf.d/local.start; \
	fi
