#!/bin/bash

set -ex

SCRIPT_NAME = $0

usage() {
cat <<EOF
Usage: $SCRIPT_NAME <VOLUME-DEVICE-PATH> 
Example: $SCRIPT_NAME  /dev/sdh
EOF
}

die() {
    msg=$1
    error_code=$2
    echo "$SCRIPT_NAME:  $msg"
    exit $error_code
}

if [ $# -ne 1 ]; then
    usage
    exit 1
else VOLUME=$1
fi

install_xfs() {
sudo apt-get install -y xfsprogs
grep -q xfs /proc/filesystems || sudo modprobe xfs
 # add the xfs module in the kernel if not already
sudo mkfs.xfs $VOLUME
}

backup_mysql() {
sudo mkdir  /vol
sudo mkdir -m 000 /vol # clearly understand why the umask option is needed
sudo cp /etc/fstab /root/fstab.backup 
cat << EOF | sudo tee -a /etc/fstab
$VOLUME   /vol   xfs   noatime 0 0  
EOF
# Check if noatime is an appropriate argument above
sudo mount -a
out=$?

if [ ! -d /vol ]; then
    error="Directory mount failed !"
    die $error $out
fi       

sudo mkdir /vol/{log,lib} /vol/etc 

sudo service mysql stop
sudo mv /etc/mysql /vol/etc/
sudo mv /var/log/mysql /vol/log/
sudo mv /var/lib/mysql /vol/lib/

sudo mkdir -p /etc/mysql
sudo mkdir -p /var/log/mysql
sudo mkdir -p /var/lib/mysql

sudo cp /etc/fstab /root/fstab.backup 
cat << EOF | sudo tee -a /etc/fstab
/vol/etc/mysql  /etc/mysql  none bind
/vol/log/mysql  /var/log/mysql  none  bind
/vol/lib/mysql  /var/lib/mysql  none  bind
EOF
sudo mount -a
sudo service mysql start
echo "*** Successfully Completed. Mysql is now running on EBS backed volume at $VOLUME ***"
}

install_xfs && backup_mysql 
out=$?
if [ $out -ne 0 ]; then
    die "Something wicked happened !" $out
fi

set +ex
