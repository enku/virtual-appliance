APP_ROOT := /var/lib/airport
AIRPORT_REPO ?= https://bitbucket.org/marduk/airport
AIRPORT_BRANCH ?= stable
PGVER := 10

preinstall:


postinstall: airport.service settings.py issue nginx.conf airport-pre.service airport-gameserver.service airport-wsgi.service
	RUN eselect postgresql set $(PGVER)
	rm -rf $(CHROOT)/var/lib/postgresql/$(PGVER)
	RUN bash -c "echo y |$(EMERGE) --config postgresql:$(PGVER)"
	RUN systemctl enable postgresql-$(PGVER)
	RUN $(EMERGE) --oneshot --noreplace $(USEPKG) dev-python/setuptools dev-python/virtualenv
	rm -rf $(CHROOT)/$(APP_ROOT)
	hg clone -u $(AIRPORT_BRANCH) $(AIRPORT_REPO) $(CHROOT)/$(APP_ROOT)
	chroot $(CHROOT) virtualenv -p /usr/bin/python3 $(APP_ROOT)
	RUN bash -c ". $(APP_ROOT)/bin/activate ; pip install -r $(APP_ROOT)/requirements.txt"
	RUN bash -c ". $(APP_ROOT)/bin/activate ; pip install psycopg2 uwsgi"
	COPY settings.py /$(APP_ROOT)/djangoproject/djangoproject
	RUN id -u airport >/dev/null || RUN useradd -d $(APP_ROOT) -M -U -G postgres airport
	RUN chown -R airport:airport $(APP_ROOT)
ifdef AIRPORT_SERIES
	cat settings_$(AIRPORT_SERIES).py >> $(CHROOT)/$(APP_ROOT)/djangoproject/djangoproject/settings.py
	RUN cp /$(APP_ROOT)/djangoproject/airport/fixtures/$(AIRPORT_SERIES).json \
		/$(APP_ROOT)/djangoproject/airport/fixtures/initial_data.json
endif
	COPY issue /etc/issue
	COPY -u airport-pre.service /etc/systemd/system/airport-pre.service
	COPY -u airport-wsgi.service /etc/systemd/system/airport-wsgi.service
	COPY -u airport-gameserver.service /etc/systemd/system/airport-gameserver.service
	$(M4) -D HOSTNAME=$(HOSTNAME) nginx.conf > $(CHROOT)/etc/nginx/nginx.conf
	RUN gpasswd -a nginx airport
	RUN systemctl enable airport-wsgi.service
	RUN systemctl enable airport-gameserver.service
ifeq ($(AVAHI),YES)
	RUN $(EMERGE) --noreplace $(USEPKG) net-dns/avahi
	RUN rm -f /etc/avahi/services/*
	COPY airport.service /etc/avahi/services
	RUN systemctl enable avahi-daemon
endif
	RUN $(EMERGE) --depclean --with-bdeps=n


clean:

