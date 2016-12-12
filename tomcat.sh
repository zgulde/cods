#!/bin/bash

# install java
sudo apt-get -y install default-jdk

header "Installing tomcat."

# download the tar from apache and extract it to /opt/tomcat
mkdir -p /opt/tomcat
cd /tmp
wget http://mirrors.ocf.berkeley.edu/apache/tomcat/tomcat-8/v8.5.9/bin/apache-tomcat-8.5.9.tar.gz
tar xzvf apache-tomcat-8.5.9.tar.gz --strip-components=1 -C /opt/tomcat
rm apache-tomcat-8.5.9.tar.gz

# create a tomcat user
sudo groupadd tomcat
sudo useradd -g tomcat -s /bin/false -d /opt/tomcat tomcat

# set permissions for the tomcat install
cd /opt/tomcat
chgrp -R tomcat conf
chmod g+rwx conf
chmod g+r conf/*
chown -R tomcat work/, temp/, logs/

# create and start the tomcat service
cp $WARPSPEED_ROOT/templates/tomcat/tomcat.conf /etc/init/tomcat.conf
initctl reload-configuration
initctl start tomcat
