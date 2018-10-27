xdm_files = $(wildcard xdm/*)

preinstall:

postinstall: $(xdm_files)
	COPY xdm/* /etc/X11/xdm
	RUN systemctl enable xdm

clean:

