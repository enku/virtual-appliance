preinstall:


postinstall:
	$(inroot) eselect python set python2.7
	$(inroot) python-updater -- --usepkg=n

	# we want sshd running
	chroot "$(CHROOT)" rc-update add sshd default

	# and root account enabled, so we can ssh in
	chroot "$(CHROOT)" chage -E -1 root

clean:

