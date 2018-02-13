##############################################################################
# Server provisioning script
#
# Contains most of the common server setup, most notably the tomcat and nginx
# config. Anything that is required for the first time server setup and requires
# root access, but does *not* require external information (e.g. the ip address
# or the user's username) lives here.
#
# This script will be run on the server by the setup script.
##############################################################################

# You might have to change the url below, the url needs to be updated
# periodically, the most recent version can be found at
# https://tomcat.apache.org/download-80.cgi
TOMCAT_DOWNLOAD_URL=http://apache.mirrors.ionfish.org/tomcat/tomcat-8/v8.5.28/bin/apache-tomcat-8.5.28.tar.gz
TOMCAT_TARGZ="$(echo $TOMCAT_DOWNLOAD_URL | perl -pe 's/.*\///')"

heading(){
	echo '----------------------------------'
	echo "> $@"
	echo '----------------------------------'
}

set -e

# setup swap file
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

heading 'updating + upgrading apt'

apt-get update
yes | apt-get upgrade

heading 'setting up nodejs repository'
curl -sL https://deb.nodesource.com/setup_8.x | bash -

heading 'installing packages'

# otherwise mysql will try to prompt us for info
export DEBIAN_FRONTEND=noninteractive

apt-get install -y\
	nginx\
	default-jdk\
	ufw\
	mysql-server\
	unattended-upgrades\
	maven\
	letsencrypt\
	nodejs

heading "Installing tomcat..."

# download the tar from apache and extract it to /opt/tomcat
mkdir -p /opt/tomcat
cd /tmp
wget $TOMCAT_DOWNLOAD_URL
tar xzvf $TOMCAT_TARGZ --strip-components=1 -C /opt/tomcat
rm $TOMCAT_TARGZ

# create a tomcat user
groupadd tomcat
useradd -g tomcat -s /bin/false -d /opt/tomcat tomcat

# configure the tomcat install
chown -R tomcat:tomcat /opt/tomcat
rm -rf /opt/tomcat/webapps/*
rm -rf /opt/tomcat/server/webapps/*
rm -f /opt/tomcat/conf/Catalina/localhost/host-manager.xml
rm -f /opt/tomcat/conf/Catalina/localhost/manager.xml
chmod -R g+w /opt/tomcat/webapps/

# replace default server config
cat > /opt/tomcat/conf/server.xml <<'server.xml'
<?xml version="1.0" encoding="UTF-8"?>
<Server port="8005" shutdown="SHUTDOWN">
  <Listener className="org.apache.catalina.startup.VersionLoggerListener" />
  <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />
  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />
  <GlobalNamingResources>
	<Resource name="UserDatabase" auth="Container"
			  type="org.apache.catalina.UserDatabase"
			  description="User database that can be updated and saved"
			  factory="org.apache.catalina.users.MemoryUserDatabaseFactory"
			  pathname="conf/tomcat-users.xml" />
  </GlobalNamingResources>
  <Service name="Catalina">
	<Connector port="8009" protocol="AJP/1.3" redirectPort="8443" />
	<Connector port="8080"
		proxyPort="80"
		protocol="HTTP/1.1"
		connectionTimeout="20000"
		redirectPort="8443" />
	<Engine name="Catalina" defaultHost="localhost">
	  <Realm className="org.apache.catalina.realm.LockOutRealm">
		<Realm className="org.apache.catalina.realm.UserDatabaseRealm"
			   resourceName="UserDatabase"/>
	  </Realm>
	  <!--## Virtual Hosts ##-->
	  <Host name="localhost" appBase="webapps" deployOnStartup="false" />
	</Engine>
  </Service>
</Server>
server.xml

# find the java installation path
java_home=$(update-java-alternatives -l | awk '{print $3}')/jre
# create the tomcat service
cat > /etc/systemd/system/tomcat.service <<tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=${java_home}
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
tomcat.service

systemctl daemon-reload

# start tomcat now, and have it start automatically on boot
systemctl enable tomcat
systemctl start tomcat

heading 'configuring nginx...'

# when files are written to the uploads directory for a specific site, they are
# created by the tomcat user, so in order for nginx to serve them, we'll add
# the www-data user to the tomcat group
usermod -a -G tomcat www-data

# remove the default nginx config
rm /etc/nginx/sites-available/default
cat > /etc/nginx/sites-available/default <<nginx_conf
# return an empty response, don't redirect to an existing server
server {
	listen 80 default_server;
	return 444;
}
nginx_conf
rm -rf /var/www/*
systemctl restart nginx

echo 'Nginx configured and restarted!'

heading 'Configuring /srv directory'

# create the git group and directory structure for deployment
groupadd git
mkdir -p /srv
chgrp git /srv
chmod g+srwx /srv
# configuration for systemd-tmpfiles
# see https://github.com/zgulde/tomcat-setup/issues/14
cp /usr/lib/tmpfiles.d/home.conf /etc/tmpfiles.d/home.conf
sed -i -e '/\/srv/ { s/0755/2775/g; }' /etc/tmpfiles.d/home.conf

heading 'Configuring Firewall...'
# firewall setup
ufw default deny incoming
ufw default allow outgoing
ufw logging on
ufw allow ssh
ufw allow http
ufw allow https
echo y | ufw enable
