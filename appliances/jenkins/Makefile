JENKINS_HOME ?= /var/lib/jenkins
JENKINS_URL = http://mirrors.jenkins-ci.org/war/latest/jenkins.war

preinstall:

create_user:
	-$(inroot) useradd --system \
		--comment "Jenkins CI" \
		--home-dir=$(JENKINS_HOME) \
		--create-home \
		jenkins


$(CHROOT)/$(JENKINS_HOME)/jenkins.war:
	$(inroot) wget -O $(JENKINS_HOME)/jenkins.war $(JENKINS_URL)


install_jenkins:
	$(MAKE) $(CHROOT)/$(JENKINS_HOME)/jenkins.war


postinstall: jenkins.service nginx.conf
	$(MAKE) create_user
	$(inroot) rm -rf $(JENKINS_HOME)
	$(inroot) mkdir -p $(JENKINS_HOME)
	$(MAKE) install_jenkins
	$(inroot) chown -R jenkins:jenkins $(JENKINS_HOME)
	cp jenkins.service $(CHROOT)/etc/systemd/system
	$(inroot) systemctl enable jenkins.service
	cp nginx.conf $(CHROOT)/etc/nginx/nginx.conf
	$(inroot) systemctl enable nginx.service

clean:


.PHONY: create_user preinstall postinstall clean install_jenkins
