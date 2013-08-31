preinstall:

postinstall: layman.cfg
	PYTHON_TARGETS="python2_7" $(inroot) $(EMERGE) $(USEPKG) -1n layman git
	cp layman.cfg "$(CHROOT)/etc/layman/layman.cfg"
	grep layman $(CHROOT)/etc/portage/make.conf || \
		echo "source /var/lib/layman/make.conf" >> $(CHROOT)/etc/portage/make.conf
	$(inroot) layman -f
	$(inroot) layman -a mgiken || $(inroot) layman --sync mgiken
	PYTHON_TARGETS="python2_7" $(inroot) $(EMERGE) -un $(USEPKG) dev-db/ArangoDB
	ln -sf /etc/init.d/arangodb $(CHROOT)/etc/runlevels/default/arangodb

clean:

