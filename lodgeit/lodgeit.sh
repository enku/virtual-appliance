#!/bin/sh

set -v

cd ~/
virtualenv --no-site-packages lodgeitproject
cd lodgeitproject
source bin/activate
[ -d lodgeit ] || hg clone http://dev.pocoo.org/hg/lodgeit-main lodgeit
pip install pygments
pip install jinja2
pip install werkzeug
pip install sqlalchemy
pip install babel
pip install pil
pip install simplejson
deactivate
