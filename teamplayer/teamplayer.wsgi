import os                                                                       
import sys
path = os.path.dirname(__file__)
sys.path.append(path)
os.environ['DJANGO_SETTINGS_MODULE'] = 'web.settings'

import django.core.handlers.wsgi

application = django.core.handlers.wsgi.WSGIHandler()

