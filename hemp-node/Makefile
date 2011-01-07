preinstall:

postinstall:
	chroot "$(CHROOT)" emerge -C '>=dev-lang/python-3.0' gentoo-sources
	# we want sshd running
	chroot "$(CHROOT)" rc-update add sshd default

	# and root account enabled, so we can ssh in
	chroot "$(CHROOT)" chage -E -1 root

clean:

