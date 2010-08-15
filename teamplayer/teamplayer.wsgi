import os                                                                       
import sys
path = os.path.dirname(`__file__')
sys.path.append(path)
sys.path.append('TP_HOME/web')
os.environ['DJANGO_SETTINGS_MODULE'] = 'settings'

import django.core.handlers.wsgi

application = django.core.handlers.wsgi.WSGIHandler()

