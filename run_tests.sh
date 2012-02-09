#!/bin/bash

set -ex
SCRIPT=$0
function usage() {
cat << EOF
Usage: $SCRIPT <UserName> <Password> <Host-IP> [SITE-NAME] [EMAIL-ADDRESS] \
[MAIN-DOMAIN]
EOF
}

function die() {
msg=$1
code=$2
echo $SCRIPT $msg 1>&2
exit $code
}

if  ! which expect  > /dev/null ; then 
    die "I need expect , please install it !\n 
    For Debian use: sudo apt-get install expect" 1
fi

#TODO -> Use getopts
USER=$1
PASS=$2
HOST=$3
SITE_NAME=${4-mydomain}
EMAIL_ADD=${5-webmaster@gmail.com}
MAIN_DOMAIN=${6-com}

#TODO -> Make it unrelative to the directory from which the script is executed
djscript=setup-django-wsgi.sh
if [ ! -f $djscript ]; then
    die "Cannot Find Script: $script_required. Did you grab the entire
repository of code ?" $?
fi

    no_hosts_args="-o StrictHostKeyChecking=no \
               -o UserKnownHostsFile=/dev/null \
               -o LogLevel=ERROR"

    if [ $USER = "root" ]; then
        PROMPT=#
    else PROMPT='\\$'
    fi
    
    expect -c "
    spawn scp $no_hosts_args $djscript ${USER}@${HOST}:~/
    expect "password:"
    send -- ${PASS}\n
    expect eof
    "

set +ex
