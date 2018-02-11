# variables: $domain

echo 'Configuring nginx...'

sudo mkdir -p /var/www/${domain}
sudo chgrp --recursive www-data /var/www/${domain}
sudo chmod g+srw /var/www/${domain}

sudo cp /srv/.templates/static-site.nginx.conf /etc/nginx/sites-available/${domain}
sudo sed -i -e s/{{domain}}/${domain}/g /etc/nginx/sites-available/${domain}
sudo ln -s /etc/nginx/sites-available/${domain} /etc/nginx/sites-enabled/${domain}
echo 'Restarting nginx...'
sudo systemctl restart nginx
