#!/bin/sh

set -v

cd ~/
[ -d lodgeitproject ] || virtualenv --no-site-packages lodgeitproject
cd lodgeitproject
. bin/activate
[ -d lodgeit ] || hg clone http://dev.pocoo.org/hg/lodgeit-main lodgeit
pip install --upgrade pygments
pip install --upgrade jinja2
pip install --upgrade werkzeug
pip install --upgrade sqlalchemy
pip install --upgrade babel
pip install --upgrade pil
pip install --upgrade simplejson
deactivate
