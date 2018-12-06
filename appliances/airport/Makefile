APP_ROOT := /var/lib/airport
AIRPORT_REPO ?= https://bitbucket.org/marduk/airport
AIRPORT_BRANCH ?= stable
PGVER := 10
repo := $(CHROOT)/$(APP_ROOT)
etc_issue := $(CHROOT)/etc/issue
services := $(wildcard *.service)
service_targets := $(patsubst %,$(CHROOT)/etc/systemd/system/%,$(services))

$(CHROOT)/etc/systemd/system/%.service: %.service
	cp $< $@
	RUN systemctl enable $<

$(etc_issue): issue
	cp $< $@

$(repo):
	hg clone -u $(AIRPORT_BRANCH) $(AIRPORT_REPO) $@

preinstall:

postinstall: settings.py issue nginx.conf $(service_targets) $(repo) $(etc_issue)
	RUN eselect postgresql set $(PGVER)
	rm -rf $(CHROOT)/var/lib/postgresql/$(PGVER)
	RUN bash -c "echo y |$(EMERGE) --config postgresql:$(PGVER)"
	RUN systemctl enable postgresql-$(PGVER)
	RUN $(EMERGE) --oneshot --noreplace $(USEPKG) dev-python/setuptools dev-python/virtualenv
	rm -rf $(CHROOT)/$(APP_ROOT)
	hg clone -u $(AIRPORT_BRANCH) $(AIRPORT_REPO) $(CHROOT)/$(APP_ROOT)
	chroot $(CHROOT) virtualenv -p /usr/bin/python3 $(APP_ROOT)
	RUN $(APP_ROOT)/bin/pip install -r $(APP_ROOT)/requirements.txt
	RUN $(APP_ROOT)/bin/pip install psycopg2 uwsgi
	COPY settings.py /$(APP_ROOT)/djangoproject/djangoproject
	RUN id -u airport >/dev/null || RUN useradd -d $(APP_ROOT) -M -U -G postgres airport
	RUN chown -R airport:airport $(APP_ROOT)
ifdef AIRPORT_SERIES
	cat settings_$(AIRPORT_SERIES).py >> $(CHROOT)/$(APP_ROOT)/djangoproject/djangoproject/settings.py
	RUN cp /$(APP_ROOT)/djangoproject/airport/fixtures/$(AIRPORT_SERIES).json \
		/$(APP_ROOT)/djangoproject/airport/fixtures/initial_data.json
endif
	$(M4) -D HOSTNAME=$(HOSTNAME) nginx.conf > $(CHROOT)/etc/nginx/nginx.conf
	RUN gpasswd -a nginx airport
	RUN systemctl enable airport-wsgi.service
	RUN systemctl enable airport-gameserver.service
	RUN $(EMERGE) --depclean --with-bdeps=n


clean:

