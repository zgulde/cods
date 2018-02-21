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

# without index file, nginx will display a 403 error when accessing the site.
# We'll put something there so that we can at least see a page to see if the
# site was properly setup
echo 'Hello, World!' > /srv/${domain}/public/index.html
