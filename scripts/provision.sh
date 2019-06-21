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

# prevent installed packages (namely mysql) from trying to prompt for
# information in an interactive way. We'll do the setup progromatically
# ourselves.
export DEBIAN_FRONTEND=noninteractive

heading 'updating + upgrading apt'

apt-get update
apt-get upgrade -y

heading 'installing packages'

apt-get install -y\
	letsencrypt nginx\
	openjdk-11-jdk-headless openjdk-8-jdk-headless maven\
	python3-venv python3-pip virtualenv\
	nodejs npm\
    php7.2-fpm php7.2-cli php7.2-bcmath php7.2-json php7.2-mbstring php7.2-xml\
    php7.2-tokenizer php7.2-mysql php7.2-sqlite3 php7.2-pgsql php7.2-zip\
	php7.2-curl php7.2-gd composer\
	ufw\
	mysql-server\
	unattended-upgrades\
	zip htop apache2-utils

heading 'configuring nginx'

# generate a stronger key for ssl connections
mkdir -p /etc/nginx/ssl
openssl dhparam -dsaparam -out /etc/nginx/ssl/dhparam.pem 2048

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
service nginx restart

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
service ufw restart
