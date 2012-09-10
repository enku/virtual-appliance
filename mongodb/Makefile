preinstall:

postinstall:
	sed -i 's/^MONGODB_IP=.*/MONGODB_IP="0.0.0.0"/' "$(CHROOT)"/etc/conf.d/mongodb
	$(inroot) rc-update add mongodb default

clean:

