# varaibles: $domain $template

username=${domain//./-}

echo "- Setting Up Git Deployment For $domain..."

sudo cp /srv/.templates/cods-config /srv/${domain}/cods-config
sudo git init --bare --shared=group /srv/${domain}/repo.git
sudo cp /srv/.templates/$template /srv/${domain}/repo.git/hooks/post-receive
sudo sed -i\
	-e s/{{site}}/$domain/g\
	-e s/{{username}}/$username/g\
	/srv/${domain}/repo.git/hooks/post-receive
sudo chmod +x /srv/${domain}/repo.git/hooks/post-receive

