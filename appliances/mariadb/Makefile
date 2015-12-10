system_conf = $(CHROOT)/etc/mysql/my.cnf
root_conf = $(CHROOT)/root/.my.cnf

preinstall:

$(system_conf): my.cnf
	cp my.cnf $(system_conf)

$(root_conf): my.cnf.root
	cp my.cnf.root $(root_conf)
	chmod 0600 $(root_conf)

postinstall: $(system_conf) $(root_conf)
	rm -rf $(CHROOT)/var/lib/mysql
	$(inroot) bash -c 'yes gentoo | emerge --config dev-db/mariadb'
	$(inroot) systemctl enable mysqld

clean:

