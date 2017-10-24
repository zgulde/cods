# this snippet expects a variable named $email to be set

# letsencrypt asks us to choose a random minute of the hour to run the renewal
# job

set -u

renew_command="/usr/bin/letsencrypt renew --agree-tos --email $email"

sudo crontab -l >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
	# no crontab yet, we will create it
	 echo "@daily sleep \$((\${RANDOM} % 60))m; $renew_command && systemctl restart nginx" | sudo crontab
else
	# check if autorenew is set up, if not, append to the current crontab
	sudo crontab -l | grep '/usr/bin/letsencrypt renew' > /dev/null
	if [[ $? -eq 0 ]]; then
		echo "It looks like we are already setup to autorenew certs"
		exit 1
	fi
	echo "$(sudo crontab -l)
@daily sleep \$((\${RANDOM} % 60))m; /usr/bin/letsencrypt renew && systemctl restart nginx"
fi
