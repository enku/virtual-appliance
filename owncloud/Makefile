preinstall:

postinstall:
	sed -i 's/^APACHE2_OPTS=.*/APACHE2_OPTS="-D DEFAULT_VHOST -D INFO -D PHP5 -D SSL -D SSL_DEFAULT_VHOST"/' $(CHROOT)/etc/conf.d/apache2
	$(inroot) rc-update add apache2 default


clean:

