# variables: $domain

echo 'Configuring nginx...'

sudo mkdir -p /srv/${domain}/public
sudo chmod g+srw /srv/${domain}
sudo chgrp tomcat /srv/${domain}/public
sudo chmod g+srw /srv/${domain}/public

sudo cp /srv/.templates/static-site.nginx.conf /etc/nginx/sites-available/${domain}
sudo sed -i -e s/{{domain}}/${domain}/g /etc/nginx/sites-available/${domain}
sudo ln -s /etc/nginx/sites-available/${domain} /etc/nginx/sites-enabled/${domain}

echo 'Restarting nginx...'
sudo systemctl restart nginx
