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

if [ $# -lt 3 ]; then
    usage 
    die "Invalid syntax" 1
fi

#TODO -> add a check for nosetests installation
#TODO -> Use getopts
USER=$1
PASS=$2
HOST=$3
SITE_NAME=${4-mydomain}
EMAIL_ADD=${5-webmaster@gmail.com}
MAIN_DOMAIN=${6-com}

#TODO -> Make it unrelative to the directory from which the script is executed
djscript=setup-django-wsgi.sh

#djscript=dummy.sh
#tilscript=utils_expect.sh

if [ ! -f $djscript ]; then
    die "Cannot Find Script: ${djscript}. Did you grab the entire
repository of code ?" $?
fi
#prompt=":|#|\\$"  

no_hosts_args="-o StrictHostKeyChecking=no \
               -o UserKnownHostsFile=/dev/null \
               -o LogLevel=ERROR"

expect  << EOF
set timeout -1 
;# exp_internal 1
set prompt ":|#|\\\\$"
spawn scp $no_hosts_args $djscript ${USER}@${HOST}:~/
expect "password:" { send -- ${PASS}\n }
expect eof
spawn ssh $no_hosts_args ${USER}@${HOST}
expect "password:" { send -- ${PASS}\n }
expect -re "\$prompt " { 
    send --  {bash ${djscript} ${SITE_NAME} ${EMAIL_ADD} ${MAIN_DOMAIN}  2>error.out}
    send -- \r 
    }
expect -re "${USER}: " { send -- ${PASS}\n } ;# password for sudo in the script
expect -re  "\$prompt " { send -- exit\r  }
expect eof  
spawn scp ${USER}@${HOST}:~/error.out .
expect "password:" { send -- ${PASS}\n }
expect -re  "\$prompt " { send -- exit\r  }
expect eof
EOF
cat error.out

#nosetests
set +ex
