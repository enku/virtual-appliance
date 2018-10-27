JENKINS_HOME ?= /var/lib/jenkins
JENKINS_URL = http://mirrors.jenkins-ci.org/war/latest/jenkins.war

preinstall:

create_user:
	-RUN useradd --system \
		--comment "Jenkins CI" \
		--home-dir=$(JENKINS_HOME) \
		--create-home \
		jenkins


$(CHROOT)/$(JENKINS_HOME)/jenkins.war:
	RUN wget -O $(JENKINS_HOME)/jenkins.war $(JENKINS_URL)


install_jenkins:
	$(MAKE) $(CHROOT)/$(JENKINS_HOME)/jenkins.war


postinstall: jenkins.service nginx.conf
	$(MAKE) create_user
	RUN rm -rf $(JENKINS_HOME)
	RUN mkdir -p $(JENKINS_HOME)
	$(MAKE) install_jenkins
	RUN chown -R jenkins:jenkins $(JENKINS_HOME)
	COPY jenkins.service /etc/systemd/system
	RUN systemctl enable jenkins.service
	COPY nginx.conf /etc/nginx/nginx.conf
	RUN systemctl enable nginx.service

clean:


.PHONY: create_user preinstall postinstall clean install_jenkins
