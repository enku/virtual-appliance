HG_REPO = ../../teamplayer
TP_USER = teamplayer
TP_HOME = /opt/teamplayer
TP_DB = /var/lib/teamplayer
PGVER = 9.0
INSTALL = install

M4_DEFS += -D TP_USER=$(TP_USER) -D TP_HOME=$(TP_HOME) -D TP_DB=$(TP_DB)
M4C = $(M4) $(M4_DEFS)

post_files = bash_profile settings_local.py start-teamplayer stop-teamplayer
post_files += local.start local.stop issue lighttpd.conf

preinstall:

postinstall: $(post_files)
	chroot $(CHROOT) $(EMERGE) -n $(USEPKG) =dev-db/postgresql-server-$(PGVER)*
	chroot $(CHROOT) passwd -d postgres
	echo 'PG_INITDB_OPTS="--locale=en_US.UTF-8"' >> $(CHROOT)/etc/conf.d/postgresql-$(PGVER)
	yes | chroot $(CHROOT) $(EMERGE) --config =postgresql-server-$(PGVER)*
	chroot $(CHROOT) rc-update add postgresql-$(PGVER) default
	chroot $(CHROOT) getent passwd $(TP_USER) || \
		chroot $(CHROOT) useradd -c "Teamplayer Server" -G postgres -U -d $(TP_HOME) $(TP_USER)
	rm -rf $(CHROOT)/$(TP_HOME)
	hg clone --pull $(HG_REPO) $(CHROOT)/$(TP_HOME)
	cp bash_profile $(CHROOT)$(TP_HOME)/.bash_profile
	chroot $(CHROOT) mkdir -p /etc/teamplayer
	$(M4C) settings_local.py > $(CHROOT)/etc/teamplayer/settings_local.py
	mkdir -p $(CHROOT)$(TP_HOME)/bin
	$(M4C) start-teamplayer > $(CHROOT)$(TP_HOME)/bin/start-teamplayer
	chmod +x $(CHROOT)$(TP_HOME)/bin/start-teamplayer
	$(M4C) stop-teamplayer > $(CHROOT)$(TP_HOME)/bin/stop-teamplayer
	chmod +x $(CHROOT)$(TP_HOME)/bin/stop-teamplayer
	chroot $(CHROOT) $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) $(TP_DB)
	chroot $(CHROOT) $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) $(TP_DB)/songs
	chroot $(CHROOT) rm -rf $(TP_HOME)/web/media/songs
	chroot $(CHROOT) ln -s $(TP_DB)/songs $(TP_HOME)/web/media/songs
	chroot $(CHROOT) $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) $(TP_DB)/mpd
	chroot $(CHROOT) $(INSTALL) -d -o $(TP_USER) -g $(TP_USER) /var/log/teamplayer
	$(M4C) local.start > $(CHROOT)/etc/conf.d/local.start
	$(M4C) local.stop > $(CHROOT)/etc/conf.d/local.stop
	cp issue $(CHROOT)/etc/issue
	$(M4C) lighttpd.conf > $(CHROOT)/etc/lighttpd/lighttpd.conf
	chroot $(CHROOT) gpasswd -a lighttpd teamplayer
	chroot $(CHROOT) rc-update add lighttpd default
	chroot $(CHROOT) rc-update add ntpd default

clean:

