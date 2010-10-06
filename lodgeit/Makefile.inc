# set up apache modules in make.conf
preinstall = cat $(APPLIANCE)/make.conf.extra >> $(CHROOT)/etc/make.conf

postinstall = chroot $(CHROOT) emerge -1n --usepkg mercurial;              \
	chroot $(CHROOT) emerge -1n --usepkg dev-python/virtualenv;            \
	chroot $(CHROOT) getent group lodgeit ||                               \
		chroot $(CHROOT) groupadd lodgeit;                                 \
	chroot $(CHROOT) getent passwd lodgeit ||                              \
    chroot $(CHROOT) useradd -c "Lodgeit Pastebin" -m -g lodgeit lodgeit;  \
	cp $(APPLIANCE)/lodgeit.sh $(CHROOT)/tmp;                              \
	chroot $(CHROOT) su -c /tmp/lodgeit.sh lodgeit;                        \
	cp $(APPLIANCE)/10_lodgeit.conf $(CHROOT)/etc/apache2/vhosts.d;        \
	cp $(APPLIANCE)/apache2.conf $(CHROOT)/etc/conf.d/apache2;             \
	python $(APPLIANCE)/genkey.py $(CHROOT);                               \
	cp $(APPLIANCE)/lodgeit.wsgi                                           \
		$(CHROOT)/home/lodgeit/lodgeitproject/lodgeit;                     \
		                                                                   \
	cp $(APPLIANCE)/issue $(CHROOT)/etc/issue;                             \
	chroot $(CHROOT) rc-update add apache2 default;                        \
	chroot $(CHROOT) emerge -C mercurial;                                  \
	chroot $(CHROOT) emerge -C dev-python/virtualenv;                      \
	chroot $(CHROOT) emerge --depclean --with-bdeps=n;
