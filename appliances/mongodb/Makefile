preinstall:
	# v8 needs python2.[67] to build but portage doesn't pull it in
	$(inroot) $(EMERGE) -1n $(USEPKG) dev-lang/python:2.7

postinstall:
	sed -i 's/127\.0\.0\.1/0.0.0.0/g' "$(CHROOT)"/etc/mongodb.conf
	$(inroot) rc-update add mongodb default

clean:

