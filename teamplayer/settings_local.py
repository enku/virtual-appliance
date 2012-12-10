TIME_ZONE = 'UTC'
DJANGO_STATIC_MEDIA = False
FORCE_SCRIPT_NAME = ''

TEMPLATE_DIRS = (
        'TP_HOME/web/teamplayer/templates',
)

TP_STREAM_URL = '/stream.mp3'
`TP_HOME' = 'TP_HOME'
DEBUG = False
TEMPLATE_DEBUG = DEBUG
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': 'teamplayer',
        'HOST': '',
        'PASSWORD': '',
        'PORT': ''
    }
}

TP_MPD_HOME = 'TP_DB/mpd'
TP_REPO_URL = '/repo/'
TP_MPD_LOG = '/dev/null'
