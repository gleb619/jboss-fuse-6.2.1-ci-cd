#!/bin/bash
set -e

echo "
timeout=10
retries=2
" >> /etc/yum.conf

yum -y install wget
wget dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
rpm -ihv epel-release-7-11.noarch.rpm
yum -y update
#yum -y install openssh-server passwd htop mtr nano which telnet unzip openssh-server sudo openssh-clients wget curl tar iptables perl git bash-completion iproute mc
yum -y install git htop mc curl
yum clean all -y

rm -rf /var/cache/yum
rm /opt/jboss/install.sh
rm -rf /opt/jboss/epel-release-7-11.noarch.rpm