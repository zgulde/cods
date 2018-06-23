# variables $domain, $port

echo "Creating user + group for ${domain}..."
sudo useradd --no-create-home ${domain} --shell /bin/false
# add admin users to new group
for user in $(ls /home) ; do sudo usermod -a -G ${domain} ${user} ; done
# and ngnix
sudo usermod -a -G ${domain} www-data

echo "Creating site directory (/srv/${domain})"
sudo mkdir -p /srv/${domain}/public
sudo chown -R ${domain}:${domain} /srv/${domain}
sudo chmod g+srw /srv/${domain}
sudo chmod g+srw /srv/${domain}/public

echo 'Configuring nginx...'
sudo cp /srv/.templates/site.nginx.conf /etc/nginx/sites-available/${domain}
sudo sed -i\
	-e s/{{domain}}/${domain}/g\
	-e s/{{port}}/${port}/g\
	/etc/nginx/sites-available/${domain}

sudo ln -s /etc/nginx/sites-available/${domain} /etc/nginx/sites-enabled/${domain}

echo 'Restarting nginx...'
sudo systemctl restart nginx

# create the service
echo 'Creating service file...'
sudo cp /srv/.templates/service-unit /etc/systemd/system/${domain}.service
sudo sed -i\
	-e s/{{user}}/${domain}/g\
	-e s/{{group}}/${domain}/g\
	-e s/{{domain}}/${domain}/g\
	-e "s!{{execstart}}!${execstart}!g"\
	/etc/systemd/system/${domain}.service

echo 'Reloading systemd...'
sudo systemctl daemon-reload
echo 'Enabling service...'
sudo systemctl enable ${domain}.service
echo 'Allow service to be restarted by non-root users...'
{
	echo "%webadmin ALL=NOPASSWD: /bin/systemctl restart ${domain}"
	echo "%webadmin ALL=NOPASSWD: /bin/journalctl --no-pager -o short-iso -u ${domain}"
	echo "%webadmin ALL=NOPASSWD: /bin/journalctl -o short-iso -f -u ${domain}"
} | sudo EDITOR='tee' visudo -f /etc/sudoers.d/${domain} >/dev/null
