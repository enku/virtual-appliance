APP_ROOT := /var/lib/airport
AIRPORT_REPO ?= https://bitbucket.org/marduk/airport
AIRPORT_BRANCH ?= stable
PGVER := 9.6

preinstall:


postinstall: airport.service settings.py issue nginx.conf airport-pre.service airport-gameserver.service airport-wsgi.service
	sed -i 's/^PG_INITDB_OPTS.*/PG_INITDB_OPTS="--locale=en_US.UTF-8"/' $(CHROOT)/etc/conf.d/postgresql-$(PGVER)
	$(inroot) eselect postgresql set $(PGVER)
	rm -rf $(CHROOT)/var/lib/postgresql/$(PGVER)
	$(inroot) bash -c "echo y |$(EMERGE) --config postgresql:$(PGVER)"
	$(inroot) systemctl enable postgresql-$(PGVER)
	$(inroot) $(EMERGE) --oneshot --noreplace $(USEPKG) dev-python/setuptools dev-python/virtualenv
	rm -rf $(CHROOT)/$(APP_ROOT)
	hg clone -u $(AIRPORT_BRANCH) $(AIRPORT_REPO) $(CHROOT)/$(APP_ROOT)
	chroot $(CHROOT) virtualenv -p /usr/bin/python3 $(APP_ROOT)
	$(inroot) bash -c ". $(APP_ROOT)/bin/activate ; pip install -r $(APP_ROOT)/requirements.txt"
	$(inroot) bash -c ". $(APP_ROOT)/bin/activate ; pip install psycopg2 uwsgi"
	cp settings.py $(CHROOT)/$(APP_ROOT)/djangoproject/djangoproject
	$(inroot) id -u airport >/dev/null || $(inroot) useradd -d $(APP_ROOT) -M -U -G postgres airport
	$(inroot) chown -R airport:airport $(APP_ROOT)
ifdef AIRPORT_SERIES
	cat settings_$(AIRPORT_SERIES).py >> $(CHROOT)/$(APP_ROOT)/djangoproject/djangoproject/settings.py
	cp $(CHROOT)/$(APP_ROOT)/djangoproject/airport/fixtures/$(AIRPORT_SERIES).json \
		$(CHROOT)/$(APP_ROOT)/djangoproject/airport/fixtures/initial_data.json
endif
	cp issue $(CHROOT)/etc/issue
	cp -u airport-pre.service $(CHROOT)/etc/systemd/system/airport-pre.service
	cp -u airport-wsgi.service $(CHROOT)/etc/systemd/system/airport-wsgi.service
	cp -u airport-gameserver.service $(CHROOT)/etc/systemd/system/airport-gameserver.service
	$(M4) -D HOSTNAME=$(HOSTNAME) nginx.conf > $(CHROOT)/etc/nginx/nginx.conf
	$(inroot) gpasswd -a nginx airport
	$(inroot) systemctl enable airport-wsgi.service
	$(inroot) systemctl enable airport-gameserver.service
ifeq ($(AVAHI),YES)
	$(inroot) $(EMERGE) --noreplace $(USEPKG) net-dns/avahi
	$(inroot) rm -f /etc/avahi/services/*
	cp airport.service $(CHROOT)/etc/avahi/services
	$(inroot) systemctl enable avahi-daemon
endif
	$(inroot) $(EMERGE) --depclean --with-bdeps=n


clean:

