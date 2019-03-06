# this snippet expects a variable named $email to be set

# letsencrypt asks us to choose a random minute of the hour to run the renewal
# job

set -u

sudo sed -e s/{{email}}/$email/g /srv/.templates/renew-https-certs.sh |\
	sudo tee /srv/renew-https-certs.sh > /dev/null
sudo chmod +x /srv/renew-https-certs.sh

# check for the presence of a crontab
sudo crontab -l >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
	# no crontab yet, we will create it
	echo "@daily /srv/renew-https-certs.sh" | sudo crontab
else
	# check if autorenew is set up, if not, append to the current crontab
	sudo crontab -l | grep '/srv/renew-https-certs.sh' > /dev/null
	if [[ $? -eq 0 ]]; then
		echo "It looks like we are already setup to autorenew certs"
		exit 1
	else
		echo "$(sudo crontab -l)
@daily /srv/renew-https-certs.sh" | sudo crontab
	fi
fi
