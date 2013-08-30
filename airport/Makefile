APP_ROOT := /var/airport
AIRPORT_REPO ?= https://bitbucket.org/marduk/airport
PGVER := 9.2

rcdefault := /etc/runlevels/default

preinstall:
	$(inroot) $(EMERGE) -n $(USEPKG) python:2.7
	$(inroot) eselect python set python2.7
	$(inroot) python-updater


postinstall: airport.service settings.py airport.wsgi default_vhost.include firstboot.start issue
	sed -i 's/^APACHE2_OPTS=.*/APACHE2_OPTS="-D DEFAULT_VHOST -D INFO -D WSGI"/' $(CHROOT)/etc/conf.d/apache2
	$(inroot) rc-update add apache2 default
	sed -i 's/^PG_INITDB_OPTS.*/PG_INITDB_OPTS="--locale=en_US.UTF-8"/' $(CHROOT)/etc/conf.d/postgresql-$(PGVER)
	$(inroot) eselect postgresql set $(PGVER)
	rm -rf $(CHROOT)/var/lib/postgresql/$(PGVER)
	yes | $(inroot) $(EMERGE) --config postgresql-server:$(PGVER)
	$(inroot) rc-update add postgresql-$(PGVER) default
	$(inroot) chsh -s /bin/sh postgres
	$(inroot) $(EMERGE) -1n $(USEPKG) dev-python/virtualenv
	rm -rf $(CHROOT)/$(APP_ROOT)
	hg clone $(AIRPORT_REPO) $(CHROOT)/$(APP_ROOT)
	echo 'VERSION="'`date +1.%y%m%d.%H%m`'"' > $(CHROOT)/$(APP_ROOT)/djangoproject/airport/__init__.py
	chroot $(CHROOT) virtualenv -p /usr/bin/python2.7 $(APP_ROOT)
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

