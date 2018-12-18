#!/bin/bash
set -e

echo "
timeout=10
retries=2
" >> /etc/yum.conf

echo "Installing deltarpm wget git htop mc curl"
yum -y install deltarpm wget
wget dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
rpm -ihv epel-release-7-11.noarch.rpm
echo "Update packages"
#yum -y update
#yum -y install openssh-server passwd htop mtr nano which telnet unzip openssh-server sudo openssh-clients wget curl tar iptables perl git bash-completion iproute mc
yum -y install git htop mc curl

echo "Cleaning after install"
yum remove -y deltarpm
yum clean all -y
sed -i -e '/timeout=10/d' /etc/yum.conf
sed -i -e '/retries=2/d' /etc/yum.conf
rm -rf /var/cache/yum
rm /opt/jboss/install.sh
rm -rf /opt/jboss/epel-release-7-11.noarch.rpm