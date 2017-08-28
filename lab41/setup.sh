#!/bin/sh

touch /didrun
# "sudo sed -i -e 's/us-west-2.ec2.archive/eu-central-1.ec2.archive/g' /etc/apt/sources.list",
apt-get update
apt install -y awscli

# yum -y update
# yum -y install httpd
# chkconfig httpd on
# /etc/init.d/httpd start
# chown ec2-user:ec2-user /var/www/html/