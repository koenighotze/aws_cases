#!/bin/sh

touch /didrun

yum -y update
yum -y install httpd
chkconfig httpd on
/etc/init.d/httpd start
chown ec2-user:ec2-user /var/www/html/