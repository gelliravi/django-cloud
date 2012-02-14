
import os
DIRNAME = os.path.abspath(os.path.dirname(__file__).decode('utf-8').replace('\\','/'))
DBNAME = os.path.join(DIRNAME,'testdb.sqlite~')
# directory name devtests is hardcoded in django-wsgi script

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3', # Add 'postgresql_psycopg2', 'postgresql', 'mysql', 'sqlite3' or 'oracle'.
        'NAME': DBNAME,                      # Or path to database file if using sqlite3.
        'USER': '',                      # Not used with sqlite3.
        'PASSWORD': '',                  # Not used with sqlite3.
        'HOST': '',                      # Set to empty string for localhost. Not used with sqlite3.
        'PORT': '',                      # Set to empty string for default. Not used with sqlite3.
    }
}

DEBUG=True
