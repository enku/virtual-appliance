preinstall:
	$(inroot) sed -i '/^APACHE2_MODULES=/d' /etc/portage/make.conf
	echo 'APACHE2_MODULES="mime alias auth_basic authz_host dir env include info"' >> $(CHROOT)/etc/portage/make.conf

postinstall:
	sed -i 's/^APACHE2_OPTS=.*/APACHE2_OPTS="-D DEFAULT_VHOST -D INFO -D PHP5 -D SSL -D SSL_DEFAULT_VHOST"/' $(CHROOT)/etc/conf.d/apache2
	$(inroot) rc-update add apache2 default


clean:

