preinstall:

postinstall: layman.cfg
	$(inroot) $(EMERGE) $(USEPKG) -n layman git
	cp layman.cfg "$(CHROOT)/etc/layman/layman.cfg"
	grep layman $(CHROOT)/etc/portage/make.conf || \
		echo "source /var/lib/layman/make.conf" >> $(CHROOT)/etc/portage/make.conf
	$(inroot) layman -S
	$(inroot) layman -a mgiken || $(inroot) layman --sync mgiken
	$(inroot) $(EMERGE) -un $(USEPKG) dev-db/ArangoDB
	ln -sf /etc/init.d/arangodb $(CHROOT)/etc/runlevels/default/arangodb

clean:

