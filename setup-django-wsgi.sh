#!/bin/bash

set -ex


usage() {
cat <<EOF
Usage: $SCRIPT_NAME <SITE-NAME> <EMAIL-ADDRESS> <MAIN-DOMAIN>
Example: $SCRIPT_NAME  mydomain  webmaster@mydomain.org  org
EOF
}

if [ $# -lt 2 ]; then
   usage
   exit 1
fi
   

SCRIPT_NAME=$0
PROJECT_ROOT=~/mywebsite
SITE_NAME=$1
ADMIN_EMAIL=$2
MEDIA_URL=/media/
MAIN_DOMAIN=${3-com}


die() {
    message=$1
    error_code=$2
    echo "$SCRIPT_NAME: $message" 1>&2
    usage
    exit $error_code
}
#TODO Use the die script in other functions

create_directories() {
mkdir -p $PROJECT_ROOT/{media,apache2,devtests}
sudo usermod -a -G www-data `whoami`
sudo chgrp -R 2750 $PROJECT_ROOT/devtests
# so that when sqlite create files permissions are inherited
}

#TODO -> make apt-get non-interactive and no ouptut
install_updates() {
sudo apt-get update && sudo apt-get upgrade -y 
}

install_baseline() {
sudo apt-get install -y git-core build-essential curl
}

install_servers() {
sudo apt-get install -y nginx apache2 libapache2-mod-wsgi
}

install_py() {
sudo apt-get install -y pep8 python python-setuptools python-dev python-django \
 python-mysqldb python-pip python-virtualenv python-sqlite python-pysqlite2 \
 sqlite3
# may include python-nose
}

basic_django() {
cd $PROJECT_ROOT
django-admin startproject $SITE_NAME
}

configure_apache() {
    cat <<EOF | sudo tee /etc/apache2/sites-available/$SITE_NAME
<VirtualHost *:80>
    ServerName www.${SITE_NAME}.${MAIN_DOMAIN}
    ServerAlias ${SITE_NAME}.${MAIN_DOMAIN}
    ServerAdmin $ADMIN_EMAIL
    LogLevel warn
    ErrorLog $PROJECT_ROOT/apache2/${SITE_NAME}_error.log
    CustomLog $PROJECT_ROOT/apache2/${SITE_NAME}_access.log combined
    #python-path=/home/$LOCAL_USER/env/lib/python2.6/site-packages  #from cosmin #ask cosmin
    
    WSGIDaemonProcess $SITE_NAME user=www-data group=www-data maximum-requests=10000 
    WSGIProcessGroup $SITE_NAME
    WSGIScriptAlias / $PROJECT_ROOT/apache2/django.wsgi

    <Directory $PROJECT_ROOT/$SITE_NAME>
        Order deny,allow
        Allow from all
    </Directory>

#TODO -> check if a directory allow,deny tag is reqd. for apache2 directory
#TODO -> ADD STATIC URL

    Alias $MEDIA_URL $PROJECT_ROOT/media/
    <Directory $PROJECT_ROOT/media>
        Order deny,allow
        Allow from all
    </Directory>
</VirtualHost>

EOF
}

configure_wsgi() {
cat << EOF | tee $PROJECT_ROOT/apache2/django.wsgi
#!/usr/bin/python

import os,sys
import django.core.handlers.wsgi

project_root='${PROJECT_ROOT}'
site_name='${SITE_NAME}'
site_root=project_root + '/' + site_name

# sys.stdout = sys.stderr # from chipy_demo by Rohit Sankaran # ask Rohit
sys.path.append(project_root)
sys.path.append(site_root)
os.environ['DJANGO_SETTINGS_MODULE'] = site_name + '.settings'

_application=django.core.handlers.wsgi.WSGIHandler()

def application(environ, start_response):
    environ['wsgi.url_scheme'] = environ.get('HTTP_X_URL_SCHEME', 'http')
    return _application(environ, start_response)

EOF
}

#Configuration fed for the dev environment
configure_settingspy() {
cat << EOF | tee -a $PROJECT_ROOT/$SITE_NAME/settings.py 


try:
    from devtests.dev_settings import *
except ImportError:
    pass

EOF
}


activate_apache() {
    sudo a2dissite default
    sudo a2ensite $SITE_NAME
    sudo /etc/init.d/apache2 reload
}

 create_directories && install_updates && install_baseline && install_servers \
  &&  install_py && basic_django && configure_apache && configure_wsgi && \
     activate_apache && configure_settingspy
 
out=$?
if [ $out -ne "0" ] ; then
   die "cannot complete process" $out
fi

set +ex 
