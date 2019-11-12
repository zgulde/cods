# variables: $domain

# The username will be the domain name with all `.`s replaced by `-`s.
# Technically a linux username can contain `.`s, but this causes some issues
# with systemd and sudoers.
username=${domain//./-}

echo "- Creating User and Group For ${domain}"
sudo useradd --no-create-home ${username} --shell /bin/false
# add admin users to new group
for user in $(ls /home) ; do sudo usermod -a -G ${username} ${user} ; done
# and ngnix
sudo usermod -a -G ${username} www-data

echo "- Creating Site Directory -- /srv/${domain}"
sudo mkdir -p /srv/${domain}/public
sudo chown -R ${username}:${username} /srv/${domain}
sudo chmod g+srw /srv/${domain}
sudo chmod g+srw /srv/${domain}/public

echo '- Creating Nginx Config'
sudo cp /srv/.templates/php-site.nginx.conf /etc/nginx/sites-available/${domain}
sudo sed -i\
	-e s/{{domain}}/${domain}/g\
	/etc/nginx/sites-available/${domain}

sudo ln -s /etc/nginx/sites-available/${domain} /etc/nginx/sites-enabled/${domain}

echo '- Restarting Nginx'
sudo systemctl restart nginx
echo '- Restarting php-fpm'
sudo systemctl restart php7.3-fpm

