# variables $domain, $port

sudo mkdir -p /srv/${domain}/public
sudo chmod g+srw /srv/${domain}
sudo chgrp tomcat /srv/${domain}/public
sudo chmod g+srw /srv/${domain}/public

# nginx config
echo 'Configuring nginx...'
sudo cp /srv/.templates/site.nginx.conf /etc/nginx/sites-available/${domain}
sudo sed -i\
	-e s/{{domain}}/${domain}/g /etc/nginx/sites-available/${domain}\
	-e s/@tomcat/@${domain}/g\
	-e s/8080/${port}/g
sudo ln -s /etc/nginx/sites-available/${domain} /etc/nginx/sites-enabled/${domain}

echo 'Restarting nginx...'
sudo systemctl restart nginx

# create the service
echo 'Creating service file...'
sed s/{{domain}}/${domain}/g /srv/.templates/node-app-service |\
	sudo tee /etc/systemd/system/${domain}.service > /dev/null

echo 'Reloading systemd...'
sudo systemctl daemon-reload
echo 'Enabling service...'
sudo systemctl enable ${domain}.service
sudo systemctl start ${domain}.service
echo 'Allow service to be restarted by non-root users...'
echo "%tomcat ALL=NOPASSWD: /bin/systemctl restart ${domain}" |\
	sudo EDITOR='tee -a' visudo -f /etc/sudoers.d/${domain} >/dev/null
