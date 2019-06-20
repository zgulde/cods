# variables: $domain, $email, $port

if egrep 'ssl\s*on;' /etc/nginx/sites-available/$domain >/dev/null ; then
	echo "It looks like https is already setup for $domain"
	echo 'Doing nothing.'
	exit 1
fi

echo '- Requesting HTTPS certificate... (this might take a second)'
sudo letsencrypt certonly\
	--authenticator webroot\
	--webroot-path=/srv/${domain}/public\
	--domain ${domain}\
	--agree-tos\
	--email $email\
	--non-interactive\
	--renew-by-default >> /srv/letsencrypt.log

echo "- Setting Up Nginx To Serve ${domain} Over Https..."

# figure out what kind of site we have
if egrep -q 'include fastcgi_params;' /etc/nginx/sites-available/$domain ; then
	template=https-php-site.nginx.conf
elif grep proxy_pass /etc/nginx/sites-available/$domain >/dev/null ; then
	template=https-site.nginx.conf
else
	template=static-https-site.nginx.conf
fi

sudo cp /srv/.templates/$template /etc/nginx/sites-available/${domain}
sudo sed -i\
	-e s/{{domain}}/${domain}/g\
	-e s/{{port}}/${port}/g\
	/etc/nginx/sites-available/${domain}
echo '- Restarting Nginx'
sudo systemctl restart nginx
