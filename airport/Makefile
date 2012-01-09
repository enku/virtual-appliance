APP_ROOT := /var/airport
HG_REPO := https://bitbucket.org/marduk/airport

preinstall:
	sed -i '/^APACHE2_/d' $(CHROOT)/etc/make.conf
	echo 'APACHE2_MPMS="prefork"' >> $(CHROOT)/etc/make.conf
	echo 'APACHE2_MODULES="auth_basic authz_host env include info"' >> $(CHROOT)/etc/make.conf


postinstall: airport.service settings.py airport.wsgi default_vhost.include firstboot.start issue
	sed -i 's/^APACHE2_OPTS=.*/APACHE2_OPTS="-D DEFAULT_VHOST -D INFO -D WSGI"/' $(CHROOT)/etc/conf.d/apache2
	$(inroot) rc-update add apache2 default
	sed -i 's/^PG_INITDB_OPTS.*/PG_INITDB_OPTS="--locale=en_US.UTF-8"/' $(CHROOT)/etc/conf.d/postgresql-9.1
	$(inroot) eselect postgresql set 9.1
	rm -rf $(CHROOT)/var/lib/postgresql/9.1
	#[ -d  $(CHROOT)/var/lib/postgresql/9.1/data ] || yes | $(inroot) $(EMERGE) --config postgresql-server:9.1
	yes | $(inroot) $(EMERGE) --config postgresql-server:9.1
	$(inroot) rc-update add postgresql-9.1 default
	$(inroot) chsh -s /bin/sh postgres
	$(inroot) $(EMERGE) -1n $(USEPKG) dev-python/virtualenv
	rm -rf $(CHROOT)/$(APP_ROOT)
	hg clone $(HG_REPO) $(CHROOT)/$(APP_ROOT)
	echo 'VERSION="'`date +1.%y%m%d.%H%m`'"' > $(CHROOT)/$(APP_ROOT)/djangoproject/airport/__init__.py
	chroot $(CHROOT) virtualenv --no-site-packages $(APP_ROOT)
	$(inroot) bash -c ". $(APP_ROOT)/bin/activate ; pip install -r $(APP_ROOT)/requirements.txt"
	$(inroot) bash -c ". $(APP_ROOT)/bin/activate ; pip install psycopg2"
	mkdir -p $(CHROOT)/$(APP_ROOT)/etc
	touch $(CHROOT)/$(APP_ROOT)/etc/__init__.py
	cp settings.py $(CHROOT)/$(APP_ROOT)/etc
	cp default_vhost.include $(CHROOT)/etc/apache2/vhosts.d
	cp airport.wsgi $(CHROOT)/var/www/localhost
	$(inroot) id -u airport >/dev/null || $(inroot) useradd -d $(APP_ROOT) -M -s /bin/false -U -G postgres airport
	$(inroot) gpasswd -a apache postgres
	cp firstboot.start $(CHROOT)/etc/local.d
	cp issue $(CHROOT)/etc/issue
ifeq ($(AVAHI),YES)
	$(inroot) $(EMERGE) -n $(USEPKG) net-dns/avahi
	$(inroot) rm -f /etc/avahi/services/*
	cp airport.service $(CHROOT)/etc/avahi/services
	$(inroot) ln -sf /etc/init.d/avahi-daemon $(rcdefault)/avahi-daemon
endif


clean:

