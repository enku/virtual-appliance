TP_REPO ?= https://bitbucket.org/marduk/teamplayer
TP_BRANCH ?= default
TP_USER = teamplayer
TP_HOME = /opt/teamplayer
TP_DB = /var/lib/teamplayer
PYTHON = $(TP_HOME)/bin/python
PGVER = 11
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
	RUN passwd -d postgres
	rm -rf $(CHROOT)/var/lib/postgresql/$(PGVER)/data
	RUN eselect postgresql unset
	RUN eselect postgresql set $(PGVER)
	RUN bash -c "echo y |$(EMERGE) --config postgresql:$(PGVER)"
ifeq ($(AVAHI),YES)
	RUN $(EMERGE) --noreplace $(USEPKG) net-dns/avahi
	RUN rm -f /etc/avahi/services/*
	COPY teamplayer.service /etc/avahi/services
	RUN systemctl enable avahi-daemon.service
endif
	RUN $(EMERGE) --oneshot --noreplace $(USEPKG) dev-python/setuptools dev-python/virtualenv dev-vcs/mercurial
	RUN getent passwd $(TP_USER) || \
		RUN useradd -c "Teamplayer Server" -G postgres -U -d $(TP_HOME) $(TP_USER)
	rm -rf $(CHROOT)/$(TP_HOME)
	mkdir -p $(CHROOT)/$(TP_HOME)
	COPY bash_profile $(TP_HOME)/.bash_profile
	RUN virtualenv $(TP_HOME)
	#RUN bash -c ". $(TP_HOME)/bin/activate ; LANG=en_US.utf8 pip install --no-cache-dir hg+$(TP_REPO)@$(TP_BRANCH)"
	RUN --setenv=LANG=en_US.utf8 $(PYTHON) -m pip install --no-cache-dir hg+$(TP_REPO)@$(TP_BRANCH)
	RUN $(PYTHON) -m pip install --no-cache-dir psycopg2 uwsgi Whoosh setproctitle
	#RUN bash -c ". $(TP_HOME)/bin/activate ; pip install --no-cache-dir psycopg2 uwsgi Whoosh setproctitle"
	#RUN bash -c ". $(TP_HOME)/bin/activate ; django-admin.py startproject project $(TP_HOME)"
	RUN $(TP_HOME)/bin/django-admin startproject project $(TP_HOME)
	chmod +x $(CHROOT)/$(TP_HOME)/manage.py
	RUN ln -sf ../manage.py $(TP_HOME)/bin/manage
	COPY urls.py $(TP_HOME)/project/urls.py
	$(M4C) settings.py >> $(CHROOT)/$(TP_HOME)/project/settings.py
ifdef SCROBBLER_AUTH
	cat $(SCROBBLER_AUTH) >> $(CHROOT)/$(TP_HOME)/project/settings.py
endif
	RUN bash -c ". $(TP_HOME)/bin/activate; cd $(TP_HOME); DJANGO_SETTINGS_MODULE=project.settings $(TP_HOME)/manage.py collectstatic --noinput"
	RUN $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) $(TP_DB)
	RUN $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) $(TP_DB)/songs
	RUN mkdir -p $(TP_HOME)/library
	RUN chown -R $(TP_USER):$(TP_USER) $(TP_HOME)
	RUN $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) $(TP_DB)/mpd
	$(M4C) teamplayer-pre.service > $(CHROOT)/etc/systemd/system/teamplayer-pre.service
	$(M4C) teamplayer-wsgi.service > $(CHROOT)/etc/systemd/system/teamplayer-wsgi.service
	$(M4C) teamplayer-spindoctor.service > $(CHROOT)/etc/systemd/system/teamplayer-spindoctor.service
	COPY issue /etc/issue
	$(M4C) nginx.conf > $(CHROOT)/etc/nginx/nginx.conf
	RUN gpasswd -a nginx teamplayer
	RUN systemctl enable teamplayer-wsgi.service
	RUN systemctl enable teamplayer-spindoctor.service
	RUN $(EMERGE) --depclean --with-bdeps=n

clean:

