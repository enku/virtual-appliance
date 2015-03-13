APP_ROOT := /var/airport
AIRPORT_REPO ?= https://bitbucket.org/marduk/airport
AIRPORT_BRANCH ?= default
PGVER := 9.4

rcdefault := /etc/runlevels/default

preinstall:


postinstall: airport.service settings.py local.start local.stop issue nginx.conf start-airport stop-airport stop-game
	sed -i 's/^PG_INITDB_OPTS.*/PG_INITDB_OPTS="--locale=en_US.UTF-8"/' $(CHROOT)/etc/conf.d/postgresql-$(PGVER)
	$(inroot) eselect postgresql set $(PGVER)
	rm -rf $(CHROOT)/var/lib/postgresql/$(PGVER)
	$(inroot) bash -c "echo y |$(EMERGE) --config postgresql:$(PGVER)"
	$(inroot) systemctl enable postgresql-$(PGVER)
	$(inroot) $(EMERGE) --oneshot --noreplace $(USEPKG) dev-python/virtualenv
	rm -rf $(CHROOT)/$(APP_ROOT)
	hg clone -u $(AIRPORT_BRANCH) $(AIRPORT_REPO) $(CHROOT)/$(APP_ROOT)
	chroot $(CHROOT) virtualenv -p /usr/bin/python3 $(APP_ROOT)
	$(inroot) bash -c ". $(APP_ROOT)/bin/activate ; pip install -r $(APP_ROOT)/requirements.txt"
	$(inroot) bash -c ". $(APP_ROOT)/bin/activate ; pip install psycopg2 uwsgi"
	mkdir -p $(CHROOT)/$(APP_ROOT)/etc
	touch $(CHROOT)/$(APP_ROOT)/etc/__init__.py
	cp settings.py $(CHROOT)/$(APP_ROOT)/etc
	$(inroot) id -u airport >/dev/null || $(inroot) useradd -d $(APP_ROOT) -M -U -G postgres airport
	mkdir -p $(CHROOT)/$(APP_ROOT)/bin
	cp start-airport $(CHROOT)/$(APP_ROOT)/bin/start-airport
	cp stop-airport $(CHROOT)/$(APP_ROOT)/bin/stop-airport
	cp stop-game $(CHROOT)/$(APP_ROOT)/bin/stop-game
	$(inroot) chown -R airport:airport $(APP_ROOT)
	cp local.start $(CHROOT)/etc/local.d/airport.start
	cp local.stop $(CHROOT)/etc/local.d/airport.stop
ifdef AIRPORT_SERIES
	cat settings_$(AIRPORT_SERIES).py >> $(CHROOT)/$(APP_ROOT)/etc/settings.py
	cp $(CHROOT)/$(APP_ROOT)/djangoproject/airport/fixtures/$(AIRPORT_SERIES).json \
		$(CHROOT)/$(APP_ROOT)/djangoproject/airport/fixtures/initial_data.json
endif
	cp issue $(CHROOT)/etc/issue
	$(M4) -D HOSTNAME=$(HOSTNAME) nginx.conf > $(CHROOT)/etc/nginx/nginx.conf
	$(inroot) gpasswd -a nginx airport
	$(inroot) systemctl enable nginx
ifeq ($(AVAHI),YES)
	$(inroot) $(EMERGE) --noreplace $(USEPKG) net-dns/avahi
	$(inroot) rm -f /etc/avahi/services/*
	cp airport.service $(CHROOT)/etc/avahi/services
	$(inroot) systemctl enable avahi-daemon
endif
	$(inroot) $(EMERGE) --depclean --with-bdeps=n


clean:

