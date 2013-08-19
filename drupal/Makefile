PGVER = 9.2
DPVER = 7.22

inroot := chroot $(CHROOT)
rcdefault := /etc/runlevels/default

preinstall: 

postinstall: firstboot.start
	$(inroot) passwd -d postgres
	echo 'PG_INITDB_OPTS="--locale=en_US.UTF-8"' >> $(CHROOT)/etc/conf.d/postgresql-$(PGVER)
	$(inroot) eselect postgresql set $(PGVER)
	rm -rf $(CHROOT)/var/lib/postgresql/$(PGVER)
	yes | $(inroot) $(EMERGE) --config =postgresql-server-$(PGVER)*
	$(inroot) ln -sf /etc/init.d/postgresql-$(PGVER) $(rcdefault)/postgresql-$(PGVER)
	$(inroot) ln -sf /etc/init.d/apache2 $(rcdefault)/apache2
	$(inroot) eselect php set apache2 1
	grep '^[^#].*PHP5' $(CHROOT)/etc/conf.d/apache2 || \
		echo 'APACHE2_OPTS="$$APACHE2_OPTS -D PHP5"' \
		>> $(CHROOT)/etc/conf.d/apache2
	$(inroot) cp /usr/share/webapps/drupal/$(DPVER)/htdocs/sites/default/default.settings.php /usr/share/webapps/drupal/$(DPVER)/htdocs/sites/default/settings.php
	[ -e "$(CHROOT)/var/www/localhost/htdocs/.webapp-drupal-$(DPVER)" ] || \
		$(inroot) webapp-config -I drupal $(DPVER)
	cp firstboot.start $(CHROOT)/etc/local.d/

clean:

