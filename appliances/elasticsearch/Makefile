ES_HOME ?= /var/lib/elasticsearch
ES_VER ?= 6.4.1
ES_TARBALL = elasticsearch-$(ES_VER).tar.gz
ES_URL = https://artifacts.elastic.co/downloads/elasticsearch/$(ES_TARBALL)

preinstall:

create_user:
	-$(inroot) useradd --system \
		--comment "Elastic Search" \
		--home-dir=$(ES_HOME) \
		--create-home \
		elastic

install_elasticsearch:
	$(inroot) test -f /usr/portage/distfiles/$(ES_TARBALL) || \
		$(inroot) wget -P /usr/portage/distfiles $(ES_URL)
	$(inroot) tar xf /usr/portage/distfiles/$(ES_TARBALL) -C $(ES_HOME)
	$(inroot) sh -c 'cd $(ES_HOME) && ln -s elasticsearch-$(ES_VER)/* .'

install_license:
	$(inroot) sh -c 'cd $(ES_HOME) && ./bin/plugin install license'

install_marvel: install_license
	$(inroot) sh -c 'cd $(ES_HOME) && ./bin/plugin install marvel-agent'
	echo 'marvel.agent.enabled: false' >> $(CHROOT)/$(ES_HOME)/config/elasticsearch.yml

postinstall: elasticsearch.service
	$(MAKE) create_user
	$(inroot) rm -rf $(ES_HOME)
	$(inroot) mkdir -p $(ES_HOME)
	$(MAKE) install_elasticsearch
	$(inroot) chown -R elastic:elastic $(ES_HOME)
	cp elasticsearch.service $(CHROOT)/etc/systemd/system
	$(inroot) systemctl enable elasticsearch.service

clean:


.PHONY: create_user preinstall postinstall clean install_elasticsearch install_marvel install_license
