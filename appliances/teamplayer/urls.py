from django.conf.urls import patterns, include, url

urlpatterns = patterns(
    '',
    (r'^accounts/login/$', 'django.contrib.auth.views.login'),
    url('^library/', include('tp_library.urls')),
    url('', include('teamplayer.urls')),
)
