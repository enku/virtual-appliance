ES_HOME ?= /var/lib/elasticsearch
ES_VER ?= 6.4.1
ES_TARBALL = elasticsearch-$(ES_VER).tar.gz
ES_URL = https://artifacts.elastic.co/downloads/elasticsearch/$(ES_TARBALL)

preinstall:

create_user:
	-RUN useradd --system \
		--comment "Elastic Search" \
		--home-dir=$(ES_HOME) \
		--create-home \
		elastic

install_elasticsearch:
	RUN test -f /usr/portage/distfiles/$(ES_TARBALL) || \
		RUN wget -P /usr/portage/distfiles $(ES_URL)
	RUN tar xf /usr/portage/distfiles/$(ES_TARBALL) -C $(ES_HOME)
	RUN sh -c 'cd $(ES_HOME) && ln -s elasticsearch-$(ES_VER)/* .'

install_license:
	RUN sh -c 'cd $(ES_HOME) && ./bin/plugin install license'

install_marvel: install_license
	RUN sh -c 'cd $(ES_HOME) && ./bin/plugin install marvel-agent'
	echo 'marvel.agent.enabled: false' >> $(CHROOT)/$(ES_HOME)/config/elasticsearch.yml

postinstall: elasticsearch.service
	$(MAKE) create_user
	RUN rm -rf $(ES_HOME)
	RUN mkdir -p $(ES_HOME)
	$(MAKE) install_elasticsearch
	RUN chown -R elastic:elastic $(ES_HOME)
	COPY elasticsearch.service /etc/systemd/system
	RUN systemctl enable elasticsearch.service

clean:


.PHONY: create_user preinstall postinstall clean install_elasticsearch install_marvel install_license
