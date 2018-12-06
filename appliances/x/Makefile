xdm_files := $(wildcard xdm/*)
xdm_targets := $(patsubst %,$(CHROOT)/etc/X11/%,$(xdm_files))


$(CHROOT)/etc/X11/xdm/%: xdm/%
	cp $< $@

preinstall:

postinstall: $(xdm_targets)
	RUN systemctl enable xdm

clean:

