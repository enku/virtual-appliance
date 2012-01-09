import os
import sys
sys.stdout = sys.stderr

import site
site.addsitedir('/var/airport/lib/python2.7/site-packages')

sys.path.append('/var/airport')
sys.path.append('/var/airport/djangoproject')
os.environ['DJANGO_SETTINGS_MODULE'] = 'etc.settings'
os.environ['VIRTUAL_ENV'] = '/var/airport/'

import django.core.handlers.wsgi
application = django.core.handlers.wsgi.WSGIHandler()

# vim: filetype=python
