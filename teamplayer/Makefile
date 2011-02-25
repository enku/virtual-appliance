HG_REPO = ../../teamplayer
TP_USER = teamplayer
TP_HOME = /opt/teamplayer
TP_DB = /var/lib/teamplayer
PGVER = 9.0
INSTALL = install
AVAHI := NO

M4_DEFS += -D TP_USER=$(TP_USER) -D TP_HOME=$(TP_HOME) -D TP_DB=$(TP_DB)
M4C = $(M4) $(M4_DEFS)

inroot := chroot $(CHROOT)

post_files = bash_profile settings_local.py start-teamplayer stop-teamplayer
post_files += local.start local.stop issue lighttpd.conf teamplayer.service

preinstall:

postinstall: $(post_files)
	$(inroot) $(EMERGE) -n $(USEPKG) =dev-db/postgresql-server-$(PGVER)*
	$(inroot) passwd -d postgres
	echo 'PG_INITDB_OPTS="--locale=en_US.UTF-8"' >> $(CHROOT)/etc/conf.d/postgresql-$(PGVER)
	yes | $(inroot) $(EMERGE) --config =postgresql-server-$(PGVER)*
	$(inroot) rc-update add postgresql-$(PGVER) default
ifeq ($(AVAHI),YES)
	$(inroot) $(EMERGE) -n $(USEPKG) net-dns/avahi
	$(inroot) rm -f /etc/avahi/services/*
	cp teamplayer.service $(CHROOT)/etc/avahi/services
	$(inroot) rc-update add avahi-daemon default
endif
	$(inroot) getent passwd $(TP_USER) || \
		$(inroot) useradd -c "Teamplayer Server" -G postgres -U -d $(TP_HOME) $(TP_USER)
	rm -rf $(CHROOT)/$(TP_HOME)
	hg clone --pull $(HG_REPO) $(CHROOT)/$(TP_HOME)
	cp bash_profile $(CHROOT)$(TP_HOME)/.bash_profile
	$(inroot) mkdir -p /etc/teamplayer
	$(M4C) settings_local.py > $(CHROOT)/etc/teamplayer/settings_local.py
	mkdir -p $(CHROOT)$(TP_HOME)/bin
	$(M4C) start-teamplayer > $(CHROOT)$(TP_HOME)/bin/start-teamplayer
	chmod +x $(CHROOT)$(TP_HOME)/bin/start-teamplayer
	$(M4C) stop-teamplayer > $(CHROOT)$(TP_HOME)/bin/stop-teamplayer
	chmod +x $(CHROOT)$(TP_HOME)/bin/stop-teamplayer
	$(inroot) $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) $(TP_DB)
	$(inroot) $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) $(TP_DB)/songs
	$(inroot) rm -rf $(TP_HOME)/web/media/songs
	$(inroot) ln -s $(TP_DB)/songs $(TP_HOME)/web/media/songs
	$(inroot) $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) $(TP_DB)/mpd
	$(inroot) $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) /var/log/teamplayer
	$(M4C) local.start > $(CHROOT)/etc/conf.d/local.start
	$(M4C) local.stop > $(CHROOT)/etc/conf.d/local.stop
	cp issue $(CHROOT)/etc/issue
	$(M4C) lighttpd.conf > $(CHROOT)/etc/lighttpd/lighttpd.conf
	$(inroot) gpasswd -a lighttpd teamplayer
	$(inroot) rc-update add lighttpd default
	$(inroot) rc-update add ntpd default

clean:

