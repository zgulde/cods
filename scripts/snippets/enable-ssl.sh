# variables: $domain, $email, $port

if egrep 'ssl\s*on;' /etc/nginx/sites-available/$domain >/dev/null ; then
	echo "It looks like SSL is already setup for $domain"
	echo 'Doing nothing.'
	exit 1
fi

echo 'Requesting SSL certificate... (this might take a second)'
sudo letsencrypt certonly\
	--authenticator webroot\
	--webroot-path=/srv/${domain}/public\
	--domain ${domain}\
	--agree-tos\
	--email $email\
	--renew-by-default >> /srv/letsencrypt.log

echo "Setting up nginx to serve ${domain} over https..."

# figure out whether we have a java site or a static one
if grep proxy_pass /etc/nginx/sites-available/$domain >/dev/null ; then
	template=ssl-site.nginx.conf
else
	template=static-ssl-site.nginx.conf
fi

sudo cp /srv/.templates/$template /etc/nginx/sites-available/${domain}
sudo sed -i -e s/{{domain}}/${domain}/g /etc/nginx/sites-available/${domain}
sudo systemctl restart nginx
