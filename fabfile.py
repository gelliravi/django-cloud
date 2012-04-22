
import os
from fabric.api import *
from fabric.contrib.files import exists, upload_template
from fabric.contrib.console import confirm

SITE_NAME = 'xenstack.com'
PROJECT_ROOT = '/home/ubuntu'

def hardcode():
    host = '46.137.214.33'
    password = ''
    user = 'ubuntu'
    key_file = '/home/deepak/.ssh/deepak-key-pair.pem'
    init(host=host, user=user, password=password, key_file=key_file)
    
def init(host='devvm', user='deepak', password='', key_file='/home/deepak/.ssh/id_rsa'):
    if password:
        env.password = password
    env.key_filename = key_file
    #TODO Check for key_file path
    env.host_string = host 
    env.user = user
    prepare_prod()

    
def usage():
    print 'fab init:host=<hostname>,user=<username>,key_file=<path-to-keyfile>'

def prepare_prod():
    install_baseline()
    install_py()
    create_directories()
    basic_django()
    install_apache()
    configure_apache()
    activate_apache()
        
def install_baseline():
    sudo('apt-get update && apt-get -y upgrade')
    sudo('apt-get install fabric')
    sudo('apt-get install -y git-core build-essential curl vim')

def install_py():
    sudo(' apt-get install -y pep8 python python-setuptools python-dev \
        python-django python-pip')
    sudo('pip install virtualenv')
    sudo('apt-get install python-mysqldb sqlite3')
    #TODO Separate out sqlite3

def create_directories():
    path = PROJECT_ROOT + '/{media,apache2}'
    run('mkdir -p ' + path )

def basic_django():
    with cd(PROJECT_ROOT):
        run('django-admin startproject ' + SITE_NAME)

def install_apache():
    sudo('apt-get install -y apache2 libapache2-mod-wsgi')

def configure_apache():
    #TODO fix this
    cwd = os.getcwd()
    temdir = os.path.join(cwd,'templates')
    dest = os.path.join('/etc/apache2/sites-available', SITE_NAME)
    context = { 'SITE_NAME': SITE_NAME, 'ADMIN_EMAIL': 'A@A.COM', 
                        'APACHE_DIR': os.path.join(PROJECT_ROOT, 'apache2') }
    upload_template('apache_site.template', 
                                     dest,
                                     context,
                                     use_jinja=True,
                                     template_dir=temdir,
                                     use_sudo=False)

def activate_apache():
    sudo('a2dissite default')
    sudo('a2ensite ' + SITE_NAME)
    sudo('/etc/init.d/apache2 reload')


