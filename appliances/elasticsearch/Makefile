ES_HOME ?= /var/lib/elasticsearch
ES_VER ?= 1.7.1
ES_TARBALL = elasticsearch-$(ES_VER).tar.gz
ES_URL = https://download.elastic.co/elasticsearch/elasticsearch/$(ES_TARBALL)

preinstall:

create_user:
	-$(inroot) useradd --system \
		--comment "Elastic Search" \
		--home-dir=$(ES_HOME) \
		--create-home \
		elastic

install_elasticsearch:
	$(inroot) test -f /usr/portage/distfiles/$(ES_TARBALL) || \
		wget -P /usr/portage/distfiles $(ES_URL)
	$(inroot) tar xf /usr/portage/distfiles/$(ES_TARBALL) -C $(ES_HOME)
	$(inroot) sh -c 'cd $(ES_HOME) && ln -s elasticsearch-$(ES_VER)/* .'

postinstall: elasticsearch.service
	$(MAKE) create_user
	$(inroot) rm -rf $(ES_HOME)
	$(inroot) mkdir -p $(ES_HOME)
	$(MAKE) install_elasticsearch
	$(inroot) chown -R elastic:elastic $(ES_HOME)
	cp elasticsearch.service $(CHROOT)/etc/systemd/system
	$(inroot) systemctl enable elasticsearch.service

clean:
