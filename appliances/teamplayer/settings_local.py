from .settings import *

#############################################################################
# Local Settings
#
# New/Overriden settings from settings_local.py
#############################################################################

import os

DEBUG = False
TEMPLATE_DEBUG = DEBUG

TIME_ZONE = 'UTC'
USE_TZ = False

# Language code for this installation. All choices can be found here:
# http://www.i18nguy.com/unicode/language-identifiers.html
LANGUAGE_CODE = 'en-us'

# If you set this to False, Django will make some optimizations so as not
# to load the internationalization machinery.
USE_I18N = False

# URL that handles the media served from MEDIA_ROOT. Make sure to use a
# trailing slash if there is a path component (optional in other cases).
# Examples: "http://media.lawrence.com", "http://example.com/media/"
MEDIA_URL = ''

STATIC_ROOT = 'static'
STATIC_URL = '/static/'
STATICFILE_FINDERS = (
    'django.contrib.staticfiles.finders.FileSystemFinder',
    'django.contrib.staticfiles.finders.AppDirectoriesFinder',
)

# List of callables that know how to import templates from various sources.
TEMPLATE_LOADERS = (
    'django.template.loaders.filesystem.Loader',
    'django.template.loaders.app_directories.Loader',
)

MIDDLEWARE_CLASSES = (
    'django.middleware.common.CommonMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'teamplayer.middleware.TeamPlayerMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
)

INSTALLED_APPS = (
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'haystack',
    'rest_framework',
    'teamplayer',
    'tp_library',
)

AUTH_PROFILE_MODULE = 'teamplayer.UserProfile'
LOGIN_REDIRECT_URL = '/'

REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'filters': {
        'require_debug_false': {
            '()': 'django.utils.log.RequireDebugFalse'
        }
    },
    'formatters': {
        'verbose': {
            'format': '%(levelname)s:%(name)s:%(asctime)s %(message)s'
        }
    },
    'handlers': {
        'mail_admins': {
            'level': 'ERROR',
            'filters': ['require_debug_false'],
            'class': 'django.utils.log.AdminEmailHandler'
        },
        'console': {
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose'
        }
    },
    'loggers': {
        'django.request': {
            'handlers': ['mail_admins'],
            'level': 'ERROR',
            'propagate': True,
        },
        'teamplayer': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        }
    }
}

ALLOWED_HOSTS = ['*']
TIME_ZONE = 'UTC'
FORCE_SCRIPT_NAME = ''
MEDIA_ROOT = 'TP_DB'

TEMPLATE_DIRS = (
        'TP_HOME/web/teamplayer/templates',
)


`TP_HOME' = 'TP_HOME'

TEAMPLAYER = {
    'STREAM_URL': '/stream.mp3',
    'MPD_HOME': 'TP_DB/mpd',
    'MPD_LOG': '/dev/null',
    'UPLOADED_LIBRARY_DIR': 'TP_HOME/library',
    'CROSSFADE': 5,
    'SHAKE_THINGS_UP': 10,
    'ALWAYS_SHAKE_THINGS_UP': True,
    'AUTOFILL_STRATEGY': 'mood',
    'HTTP_PORT': 8000,
}

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': 'teamplayer',
        'HOST': '',
        'PASSWORD': '',
        'PORT': '',
        'CONN_MAX_AGE': 300,
    }
}


# haystack
HAYSTACK_CONNECTIONS = {
    'default': {
        'ENGINE': 'haystack.backends.whoosh_backend.WhooshEngine',
        'PATH': os.path.join(`TP_HOME', 'library_index'),
    },
}

HAYSTACK_SIGNAL_PROCESSOR = 'haystack.signals.RealtimeSignalProcessor'
HAYSTACK_CUSTOM_HIGHLIGHTER = 'tp_library.Highlighter'
