# varaibles: $domain

echo "Setting up git deployment for $domain..."

# figure out what type of site we have to determine which template to use
if grep proxy_pass /etc/nginx/sites-available/$domain >/dev/null ; then
	template=post-receive.sh
else
	template=post-receive-static.sh
fi

mkdir /srv/${domain}
cp /srv/.templates/config /srv/${domain}/config
git init --bare --shared=group /srv/${domain}/repo.git
cp /srv/.templates/$template /srv/${domain}/repo.git/hooks/post-receive
sed -i -e s/{{site}}/$domain/g /srv/${domain}/repo.git/hooks/post-receive
chmod +x /srv/${domain}/repo.git/hooks/post-receive

