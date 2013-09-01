preinstall:
	# v8 needs python2.[67] to build but portage doesn't pull it in
	$(inroot) $(EMERGE) -1n $(USEPKG) dev-lang/python:2.7

postinstall:
	sed -i 's/^MONGODB_IP=.*/MONGODB_IP="0.0.0.0"/' "$(CHROOT)"/etc/conf.d/mongodb
	$(inroot) rc-update add mongodb default

clean:

