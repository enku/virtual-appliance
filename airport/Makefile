APP_ROOT := /var/airport
AIRPORT_REPO ?= https://bitbucket.org/marduk/airport
PGVER := 9.3

rcdefault := /etc/runlevels/default

preinstall:


postinstall: airport.service settings.py firstboot.start zzairport.start issue nginx.conf
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
	chroot $(CHROOT) virtualenv -p /usr/bin/python3.2 $(APP_ROOT)
	$(inroot) bash -c ". $(APP_ROOT)/bin/activate ; pip install -r $(APP_ROOT)/requirements.txt"
	$(inroot) bash -c ". $(APP_ROOT)/bin/activate ; pip install psycopg2 uwsgi"
	mkdir -p $(CHROOT)/$(APP_ROOT)/etc
	touch $(CHROOT)/$(APP_ROOT)/etc/__init__.py
	cp settings.py $(CHROOT)/$(APP_ROOT)/etc
	$(inroot) id -u airport >/dev/null || $(inroot) useradd -d $(APP_ROOT) -M -s /bin/false -U -G postgres airport
	$(inroot) chown -R airport:airport $(APP_ROOT)
	cp firstboot.start $(CHROOT)/etc/local.d
	cp zzairport.start $(CHROOT)/etc/local.d
	cp issue $(CHROOT)/etc/issue
	$(M4) -D HOSTNAME=$(HOSTNAME) nginx.conf > $(CHROOT)/etc/nginx/nginx.conf
	$(inroot) ln -sf /etc/init.d/nginx $(rcdefault)/nginx
ifeq ($(AVAHI),YES)
	$(inroot) $(EMERGE) -n $(USEPKG) net-dns/avahi
	$(inroot) rm -f /etc/avahi/services/*
	cp airport.service $(CHROOT)/etc/avahi/services
	$(inroot) ln -sf /etc/init.d/avahi-daemon $(rcdefault)/avahi-daemon
endif
	$(inroot) $(EMERGE) --depclean --with-bdeps=n


clean:

