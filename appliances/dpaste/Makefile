PGVER = 9.3
DPASTE_USER = dpaste
DPASTE_HOME = /opt/dpaste
PIP = $(DPASTE_HOME)/bin/pip
DPASTE_REPO = https://github.com/bartTC/dpaste

rcdefault := /etc/runlevels/default

preinstall:

postinstall: bash_profile nginx.conf dpaste.init settings.py firstboot.start
	$(inroot) $(EMERGE) $(USEPKG) --oneshot --noreplace dev-vcs/git
	$(inroot) $(EMERGE) --noreplace $(USEPKG) dev-db/postgresql:$(PGVER)
	$(inroot) passwd -d postgres
	$(inroot) eselect postgresql set $(PGVER)
	$(inroot) rm -rf /var/lib/postgresql/$(PGVER)/data
	$(inroot) bash -c "echo y |$(EMERGE) --config postgresql:$(PGVER)"
	$(inroot) systemctl enable postgresql-$(PGVER)
	$(inroot) $(EMERGE) --oneshot --noreplace $(USEPKG) dev-python/virtualenv
	$(inroot) getent passwd $(DPASTE_USER) || \
		$(inroot) useradd -c "Dpaste Server" -G postgres -U -d $(DPASTE_HOME) $(DPASTE_USER)
	rm -rf $(CHROOT)/$(DPASTE_HOME)
	mkdir -p $(CHROOT)/$(DPASTE_HOME)
	mkdir -p $(CHROOT)/$(DPASTE_HOME)/media
	mkdir -p $(CHROOT)/$(DPASTE_HOME)/var
	$(inroot) rm -rf $(DPASTE_HOME)/dpaste 
	$(inroot) git clone $(DPASTE_REPO) $(DPASTE_HOME)/dpaste
	sed -i 's/dpaste\.de/dpaste/g' $(CHROOT)/$(DPASTE_HOME)/dpaste/dpaste/templates/dpaste/*.html
	cp bash_profile $(CHROOT)$(DPASTE_HOME)/.bash_profile
	$(inroot) virtualenv -p /usr/bin/python2.7 $(DPASTE_HOME)
	$(inroot) $(PIP) install -r $(DPASTE_HOME)/dpaste/requirements.txt
	$(inroot) $(PIP) install psycopg2
	$(inroot) $(DPASTE_HOME)/bin/django-admin.py startproject project $(DPASTE_HOME)
	grep ^SECRET_KEY $(CHROOT)/$(DPASTE_HOME)/project/settings.py > $(CHROOT)/$(DPASTE_HOME)/project/keyfile.py
	cp settings.py $(CHROOT)/$(DPASTE_HOME)/project/settings.py
	chmod +x $(CHROOT)/$(DPASTE_HOME)/manage.py
	cp nginx.conf $(CHROOT)/etc/nginx
	cp dpaste.init $(CHROOT)/etc/init.d/dpaste
	cp firstboot.start $(CHROOT)/etc/local.d/firstboot.start
	touch $(CHROOT)/firstboot
	$(inroot) systemctl enable nginx
	$(inroot) ln -sf ../manage.py $(DPASTE_HOME)/bin/manage
	$(inroot) $(EMERGE) --depclean --with-bdeps=n


clean:

