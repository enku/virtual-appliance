import sys
from os.path import dirname
app_dir = dirname(__file__)
sys.path.insert(0, app_dir)
from lodgeit import make_app
from app_config import key

application = make_app(
    dburi='sqlite:///%s/lodgeit.db' % app_dir,
    secret_key=key
)

