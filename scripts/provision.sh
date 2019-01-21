##############################################################################
# Server provisioning script
#
# Contains most of the common server setup, most notably the nginx config.
# Anything that is required for the first time server setup and requires root
# access, but does *not* require external information (e.g. the server's ip
# address or the user's username) lives here.
#
# This script will be run on the server by the setup script.
##############################################################################

heading(){
	echo '----------------------------------'
	echo "> $@"
	echo '----------------------------------'
}

set -e

heading 'updating + upgrading apt'

heading '[DEBUG] setting DEBIAN_FRONTEND=noninteractive'

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y

heading 'setting up nodejs repository'
curl -sL https://deb.nodesource.com/setup_8.x | bash -

heading 'installing packages'

apt-get install -y\
	nginx\
	default-jdk\
	ufw\
	mysql-server\
	unattended-upgrades\
	maven\
	letsencrypt\
	python3-venv\
	nodejs

heading 'configuring nginx...'

# group we'll use use for all of our web-admin needs
groupadd web

# add the user that nginx runs as to the web group
usermod -a -G web www-data

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
# don't expose OS and version information
sed -i -e 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf
systemctl restart nginx

echo 'Nginx configured and restarted!'

heading 'Configuring /srv directory'

mkdir -p /srv
chgrp web /srv
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
