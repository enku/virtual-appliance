# set up apache modules in make.conf

POST_FILES = lodgeit.sh 10_lodgeit.conf apache2.conf genkey.py lodgeit.wsgi
POST_FILES += issue

preinstall: make.conf.extra
	cat make.conf.extra >> $(CHROOT)/etc/make.conf

postinstall: $(POST_FILES)
	chroot $(CHROOT) $(EMERGE) -1n $(USEPKG) dev-vcs/mercurial
	chroot $(CHROOT) $(EMERGE) -1n $(USEPKG) dev-python/virtualenv
	chroot $(CHROOT) getent group lodgeit || chroot $(CHROOT) groupadd lodgeit
	chroot $(CHROOT) getent passwd lodgeit || \
		chroot $(CHROOT) useradd -c "Lodgeit Pastebin" -m -g lodgeit lodgeit
	cp lodgeit.sh $(CHROOT)/tmp
	chroot $(CHROOT) su -c /tmp/lodgeit.sh lodgeit
	cp 10_lodgeit.conf $(CHROOT)/etc/apache2/vhosts.d
	cp apache2.conf $(CHROOT)/etc/conf.d/apache2
	python genkey.py $(CHROOT)
	cp lodgeit.wsgi $(CHROOT)/home/lodgeit/lodgeitproject/lodgeit
	cp issue $(CHROOT)/etc/issue
	chroot $(CHROOT) rc-update add apache2 default
	chroot $(CHROOT) $(EMERGE) -C dev-vcs/mercurial
	chroot $(CHROOT) $(EMERGE) -C dev-python/virtualenv
	chroot $(CHROOT) $(EMERGE) --depclean --with-bdeps=n

clean:

