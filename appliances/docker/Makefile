preinstall:

postinstall: 30-ipforward.conf eth.network
	cp 30-ipforward.conf $(CHROOT)/etc/sysctl.d/
	cp eth.network $(CHROOT)/etc/systemd/network/
	$(inroot) systemctl enable docker.service

clean:

