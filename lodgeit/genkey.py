#!/usr/bin/python

import os
import sys

AC_FILENAME = "%s/home/lodgeit/lodgeitproject/lodgeit/app_config.py" % sys.argv[1]

key=repr(os.urandom(30))
app_config=open(AC_FILENAME, 'w')
app_config.write('key=%s\n' % repr(key))
app_config.close()
