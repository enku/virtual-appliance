VABUILDER_HOME = /var/lib/vabuilder
VABUILDER_REPO = https://bitbucket.org/marduk/virtual-appliance/
VABUILDER_REV = default

M4_DEFS += -D VABUILDER_HOME=$(VABUILDER_HOME) -D HOSTNAME=$(HOSTNAME)
M4C = $(M4) $(M4_DEFS)

preinstall:

postinstall: nginx.conf.m4
	RUN rm -rf $(VABUILDER_HOME)
	RUN hg clone -u $(VABUILDER_REV) $(VABUILDER_REPO) $(VABUILDER_HOME)
	RUN ln -nsf $(VABUILDER_HOME) /root/vabuilder
	$(M4C) nginx.conf.m4 > $(CHROOT)/etc/nginx/nginx.conf
	RUN systemctl enable nginx.service


clean:

