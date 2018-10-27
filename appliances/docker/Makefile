preinstall:

postinstall: 30-ipforward.conf eth.network
	COPY 30-ipforward.conf /etc/sysctl.d/
	COPY eth.network /etc/systemd/network/
	RUN systemctl enable docker.service

clean:

