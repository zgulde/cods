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

apt-mark hold cloud-init
apt-get update
apt-get upgrade -y
apt-get install -y gnupg2 software-properties-common curl # we need this first to setup new repos

heading 'Adding adoptopenjdk repos'

apt-key add <(curl -LSs https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public)
sudo add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
sudo apt-get update

heading 'installing packages'

apt-get install -y\
	letsencrypt nginx\
	adoptopenjdk-8-hotspot adoptopenjdk-11-hotspot maven\
	python3-venv python3-pip virtualenv\
	nodejs npm\
    php7.3-fpm php7.3-cli php7.3-bcmath php7.3-json php7.3-mbstring php7.3-xml\
    php7.3-tokenizer php7.3-mysql php7.3-sqlite3 php7.3-pgsql php7.3-zip\
	php7.3-curl php7.3-gd composer\
	ufw\
	haveged\
	unattended-upgrades\
	zip htop tmux apache2-utils mg

heading 'setting default umask'

echo 'umask 002' > /etc/profile.d/group_umask.sh

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
