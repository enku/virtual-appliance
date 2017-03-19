TP_REPO ?= https://bitbucket.org/marduk/teamplayer
TP_BRANCH ?= default
TP_USER = teamplayer
TP_HOME = /opt/teamplayer
TP_DB = /var/lib/teamplayer
PGVER = 9.6
INSTALL = install
AVAHI := NO

M4_DEFS += -D TP_USER=$(TP_USER) -D TP_HOME=$(TP_HOME) -D TP_DB=$(TP_DB) -D HOSTNAME=$(HOSTNAME) -D PGVER=$(PGVER)
M4C = $(M4) $(M4_DEFS)

rcdefault := /etc/runlevels/default

post_files = bash_profile settings.py teamplayer-pre.service
post_files += teamplayer-wsgi.service teamplayer-spindoctor.service
post_files += issue nginx.conf teamplayer.service

preinstall:

postinstall: $(post_files) $(SCROBBLER_AUTH) urls.py
	$(inroot) $(EMERGE) --noreplace $(USEPKG) dev-db/postgresql:$(PGVER)
	$(inroot) passwd -d postgres
	$(inroot) eselect postgresql set $(PGVER)
	$(inroot) rm -rf /var/lib/postgresql/$(PGVER)/data
	$(inroot) bash -c "echo y |$(EMERGE) --config postgresql:$(PGVER)"
ifeq ($(AVAHI),YES)
	$(inroot) $(EMERGE) --noreplace $(USEPKG) net-dns/avahi
	$(inroot) rm -f /etc/avahi/services/*
	cp teamplayer.service $(CHROOT)/etc/avahi/services
	$(inroot) systemctl enable avahi-daemon.service
endif
	$(inroot) $(EMERGE) --oneshot --noreplace $(USEPKG) dev-python/setuptools dev-python/virtualenv dev-vcs/mercurial
	$(inroot) getent passwd $(TP_USER) || \
		$(inroot) useradd -c "Teamplayer Server" -G postgres -U -d $(TP_HOME) $(TP_USER)
	rm -rf $(CHROOT)/$(TP_HOME)
	mkdir -p $(CHROOT)/$(TP_HOME)
	cp bash_profile $(CHROOT)$(TP_HOME)/.bash_profile
	$(inroot) virtualenv $(TP_HOME)
	$(inroot) bash -c ". $(TP_HOME)/bin/activate ; LANG=en_US.utf8 pip install --no-cache-dir hg+$(TP_REPO)@$(TP_BRANCH)"
	$(inroot) bash -c ". $(TP_HOME)/bin/activate ; pip install --no-cache-dir psycopg2 uwsgi Whoosh setproctitle"
	$(inroot) bash -c ". $(TP_HOME)/bin/activate ; django-admin.py startproject project $(TP_HOME)"
	chmod +x $(CHROOT)/$(TP_HOME)/manage.py
	$(inroot) ln -sf ../manage.py $(TP_HOME)/bin/manage
	cp urls.py $(CHROOT)/$(TP_HOME)/project/urls.py
	$(M4C) settings.py >> $(CHROOT)/$(TP_HOME)/project/settings.py
ifdef SCROBBLER_AUTH
	cat $(SCROBBLER_AUTH) >> $(CHROOT)/$(TP_HOME)/project/settings.py
endif
	$(inroot) bash -c ". $(TP_HOME)/bin/activate; cd $(TP_HOME); DJANGO_SETTINGS_MODULE=project.settings $(TP_HOME)/manage.py collectstatic --noinput"
	$(inroot) $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) $(TP_DB)
	$(inroot) $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) $(TP_DB)/songs
	$(inroot) mkdir -p $(TP_HOME)/library
	$(inroot) chown -R $(TP_USER):$(TP_USER) $(TP_HOME)
	$(inroot) $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) $(TP_DB)/mpd
	$(M4C) teamplayer-pre.service > $(CHROOT)/etc/systemd/system/teamplayer-pre.service
	$(M4C) teamplayer-wsgi.service > $(CHROOT)/etc/systemd/system/teamplayer-wsgi.service
	$(M4C) teamplayer-spindoctor.service > $(CHROOT)/etc/systemd/system/teamplayer-spindoctor.service
	cp issue $(CHROOT)/etc/issue
	$(M4C) nginx.conf > $(CHROOT)/etc/nginx/nginx.conf
	$(inroot) gpasswd -a nginx teamplayer
	$(inroot) systemctl enable teamplayer-wsgi.service
	$(inroot) systemctl enable teamplayer-spindoctor.service
	$(inroot) $(EMERGE) --depclean --with-bdeps=n

clean:

