# varaibles: $domain $template

echo "- Setting Up Git Deployment For $domain..."

sudo cp /srv/.templates/config /srv/${domain}/config
sudo git init --bare --shared=group /srv/${domain}/repo.git
sudo cp /srv/.templates/$template /srv/${domain}/repo.git/hooks/post-receive
sudo sed -i -e s/{{site}}/$domain/g /srv/${domain}/repo.git/hooks/post-receive
sudo chmod +x /srv/${domain}/repo.git/hooks/post-receive

