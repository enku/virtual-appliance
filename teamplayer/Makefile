TP_REPO ?= ../../teamplayer
TP_USER = teamplayer
TP_HOME = /opt/teamplayer
TP_DB = /var/lib/teamplayer
PGVER = 9.3
INSTALL = install
AVAHI := NO

M4_DEFS += -D TP_USER=$(TP_USER) -D TP_HOME=$(TP_HOME) -D TP_DB=$(TP_DB) -D TP_HOSTNAME=$(HOSTNAME)
M4C = $(M4) $(M4_DEFS)

inroot := chroot $(CHROOT)
rcdefault := /etc/runlevels/default

post_files = bash_profile settings_local.py start-teamplayer stop-teamplayer
post_files += local.start local.stop issue lighttpd.conf teamplayer.service

preinstall:
	$(inroot) $(EMERGE) --select -n $(USEPKG) dev-lang/python:2.7
	$(inroot) eselect python set python2.7
	$(inroot) python-updater

postinstall: $(post_files) $(SCROBBLER_AUTH) urls.py
	$(inroot) $(EMERGE) -n $(USEPKG) dev-db/postgresql-server:$(PGVER)
	$(inroot) passwd -d postgres
	echo 'PG_INITDB_OPTS="--locale=en_US.UTF-8"' >> $(CHROOT)/etc/conf.d/postgresql-$(PGVER)
	$(inroot) eselect postgresql set $(PGVER)
	$(inroot) rm -rf /var/lib/postgresql/$(PGVER)/data
	yes | $(inroot) $(EMERGE) --config postgresql-server:$(PGVER)
	$(inroot) ln -sf /etc/init.d/postgresql-$(PGVER) $(rcdefault)/postgresql-$(PGVER)
ifeq ($(AVAHI),YES)
	$(inroot) $(EMERGE) -n $(USEPKG) net-dns/avahi
	$(inroot) rm -f /etc/avahi/services/*
	cp teamplayer.service $(CHROOT)/etc/avahi/services
	$(inroot) ln -sf /etc/init.d/avahi-daemon $(rcdefault)/avahi-daemon
endif
	$(inroot) $(EMERGE) -1n $(USEPKG) dev-python/virtualenv
	$(inroot) getent passwd $(TP_USER) || \
		$(inroot) useradd -c "Teamplayer Server" -G postgres -U -d $(TP_HOME) $(TP_USER)
	rm -rf $(CHROOT)/$(TP_HOME)
	mkdir -p $(CHROOT)/$(TP_HOME)
	hg clone --pull $(TP_REPO) $(CHROOT)/$(TP_HOME)/teamplayer
	cp bash_profile $(CHROOT)$(TP_HOME)/.bash_profile
	$(inroot) virtualenv $(TP_HOME)
	$(inroot) bash -c ". $(TP_HOME)/bin/activate ; pip install -e $(TP_HOME)/teamplayer"
	$(inroot) bash -c ". $(TP_HOME)/bin/activate ; pip install psycopg2 flup Whoosh setproctitle"
	$(inroot) bash -c ". $(TP_HOME)/bin/activate ; django-admin.py startproject project $(TP_HOME)"
	chmod +x $(CHROOT)/$(TP_HOME)/manage.py
	$(inroot) ln -sf ../manage.py $(TP_HOME)/bin/manage
	cp urls.py $(CHROOT)/$(TP_HOME)/project/urls.py
	$(M4C) settings_local.py >> $(CHROOT)/$(TP_HOME)/project/settings_local.py
ifdef SCROBBLER_AUTH
	cat $(SCROBBLER_AUTH) >> $(CHROOT)/$(TP_HOME)/project/settings_local.py
endif
	mkdir -p $(CHROOT)$(TP_HOME)/bin
	$(M4C) start-teamplayer > $(CHROOT)$(TP_HOME)/bin/start-teamplayer
	chmod +x $(CHROOT)$(TP_HOME)/bin/start-teamplayer
	$(M4C) stop-teamplayer > $(CHROOT)$(TP_HOME)/bin/stop-teamplayer
	chmod +x $(CHROOT)$(TP_HOME)/bin/stop-teamplayer
	$(inroot) $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) $(TP_DB)
	$(inroot) $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) $(TP_DB)/songs
	$(inroot) mkdir -p $(TP_HOME)/library
	$(inroot) chown -R $(TP_USER):$(TP_USER) $(TP_HOME)
	$(inroot) $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) $(TP_DB)/mpd
	$(inroot) $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) /var/log/teamplayer
	$(M4C) local.start > $(CHROOT)/etc/local.d/teamplayer.start
	$(M4C) local.stop > $(CHROOT)/etc/local.d/teamplayer.stop
	$(inroot) chmod +x /etc/local.d/teamplayer.start
	$(inroot) chmod +x /etc/local.d/teamplayer.stop
	cp issue $(CHROOT)/etc/issue
	$(M4C) lighttpd.conf > $(CHROOT)/etc/lighttpd/lighttpd.conf
	$(inroot) gpasswd -a lighttpd teamplayer

	$(inroot) ln -sf /etc/init.d/lighttpd $(rcdefault)/lighttpd
	$(inroot) ln -sf /etc/init.d/ntpd $(rcdefault)/ntpd
	$(inroot) $(EMERGE) --depclean --with-bdeps=n

clean:

