preinstall:


postinstall:
	sed -i 's/127\.0\.0\.1/0.0.0.0/g' "$(CHROOT)"/etc/mongodb.conf
	RUN systemctl enable mongodb.service

clean:

