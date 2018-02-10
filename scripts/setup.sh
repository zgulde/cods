##############################################################################
# First time setup script
#
# This script will be invoked when the `.env` file is not found, when running
# the `server` command for the first time. It will perform all the first time
# setup, as well as run the provision script on the server
##############################################################################

# check for the utilities we'll need
# these should be available on a default osx install
prereqs=(perl dig ssh scp)
for tool in ${prereqs[@]}; do
	which $tool >/dev/null
	if [[ $? -ne 0 ]]; then
		echo "Please install '$tool' before continuing."
		exit 1
	fi
done

heading(){
	echo '----------------------------------'
	echo "> $@"
	echo '----------------------------------'
}

if [[ -e ./.env ]]; then
	echo 'It looks like things are already setup, aborting...'
	echo 'To redo the setup process, delete the ".env" file'
	exit 1
fi

read -p 'Enter the servers ip address: ' ip
echo
echo 'Since this will be the first time we will have connected to your server,'
echo 'you will be prompted whether or not you trust the server. Type yes when'
echo 'prompted.'
echo
# make sure we can access that server
ssh root@$ip ls > /dev/null
if [[ $? -ne 0 ]]; then
	echo "Cannot login to $ip!"
	echo 'Make sure:'
	echo '  - The ip address is correct'
	echo '  - Your public key is on the server'
	echo '  - The server is "fresh" (not setup manually or by another tool)'
	echo 'and try again.'
	exit 1
fi

echo
echo 'You will need to now choose a username for the server. This is the user'
echo 'you will log in as, as well as the database administrator user that'
echo 'will be setup.'
echo
echo 'A username should start with a lowercase letter, and only consist of'
echo 'lowercase letters, numbers, or the "_" character. It should also'
echo 'be no longer than 30 characters.'
echo
echo 'Usually it is fine (and easier) to use the same username as the one on'
echo 'your local machine, but if your local username does not match the given'
echo 'rules, you should choose something different.'
echo
read -p "Enter a username (default $USER): " user
if [[ -z "$user" ]]; then
	user=$USER
fi
# validate username
if [[ "$user" == "root" ]]; then
	echo 'Username cannot be "root". Aborting...'
	echo 'Server not setup, and no configuration file created.'
	echo 'Try running the script again.'
	exit 1
fi
perl -ne 'exit 1 unless /^[a-z][a-z0-9_]{0,29}$/' <<< "$user"
if [[ $? -ne 0 ]]; then
	echo "Ivalid username: '$user'! Aborting..."
	echo 'Server not setup, and no configuration file created.'
	echo 'Make sure your username matches the given rules, and try running'
	echo 'the script again.'
	exit 1
fi

echo
echo 'We will need an email address for obtaining a ssl certificate, while this'
echo 'is optional, it is recommended so that you can be contacted if anything'
echo 'goes wrong with your site.'
echo
read -p 'email: ' email
echo

password=$(LC_ALL=C tr -cd 'a-zA-Z0-9' < /dev/urandom | head -c 16)
db_password=$(LC_ALL=C tr -cd 'a-zA-Z0-9' < /dev/urandom | head -c 16)

echo "Here are your auto-generated passwords for the server:"
echo
echo "Sudo Password: $password" | tee -a "$BASE_DIR/credentials.txt"
echo "DB Password:   $db_password" | tee -a "$BASE_DIR/credentials.txt"
echo
echo 'These have been saved to "credentials.txt".'
echo
echo '+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Warning ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+'
echo '| For security purposes, it is advised you delete the credentials.txt  |'
echo '| file and move these into a password manager                          |'
echo '+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+'
echo
echo 'Next, we will provision the server. Please be patient, as this process'
echo 'can take a few minutes.'
echo
read -p 'Press <Enter> to continue and setup the server'

# create the .env file
cat > $ENV_FILE <<EOF
ip=$ip
user=$user
email=$email
EOF

echo '".env" file created!'

heading 'running provision script'

ssh root@$ip bash < $SCRIPTS/provision.sh

# make sure provisioning went okay
if [[ $? -ne 0 ]]; then
	echo
	echo 'Uh oh! Looks like something went wrong with the server provisioning!'
	echo
	echo 'Check the above output for more details. Is the tomcat download url'
	echo 'up to date? (Check scripts/provision.sh) and https://tomcat.apache.org/download-80.cgi.'
	echo
	echo 'To re-provision, you should:'
	echo '  1. Re-image your server'
	echo '  2. Remove the ".env" and "credentials.txt" file from this directory'
	echo '  3. Edit "~/.ssh/known_hosts" and remove the entry for the servers ip'
	echo '  4. Re-run this script'
	echo
	exit 1
fi

heading 'securing mysql installation...'

# secure the mysql install
ssh root@$ip 'mysql -u root' <<sql
CREATE USER $user@localhost IDENTIFIED BY '$db_password';
GRANT ALL ON *.* TO $user@localhost WITH GRANT OPTION;
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$db_password');
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
FLUSH PRIVILEGES;
sql

[[ $? -eq 0 ]] && echo 'MySQL configured!'

heading 'creating user'

ssh root@$ip bash <<setup_user
# create the git group and directory structure for deployment
groupadd git
mkdir -p /srv
chgrp git /srv
chmod g+srwx /srv
# create a user and add the ssh key
useradd --create-home --shell /bin/bash --groups sudo,tomcat,git,www-data $user
echo '$user:$password' | chpasswd
# copy over ssh key config for the new user
mkdir -p /home/$user/.ssh
cp \$HOME/.ssh/authorized_keys /home/$user/.ssh/
chown --recursive $user:$user /home/$user/.ssh

# disable password login + root login
perl -i -pe 's/(PasswordAuthentication\s*)yes/\1no/' /etc/ssh/sshd_config
perl -i -pe 's/(PermitRootLogin\s*)yes/\1no/' /etc/ssh/sshd_config
service sshd restart
service ssh restart
setup_user

[[ $? -eq 0 ]] && echo 'User created and ssh locked down!'

heading 'Finsihed Server Provisioning!'

COMMAND_NAME=$(basename $BASE_DIR)
heading "Setting up '$COMMAND_NAME' command..."
if which $COMMAND_NAME >/dev/null ; then
	echo "it looks like you already have a command named $COMMAND_NAME"
	echo 'We will skip this part of the setup.'
else
	echo "Linking ~/opt/bin/$COMMAND_NAME to $BASE_DIR/server..."
	mkdir -p ~/opt/bin
	ln -s $BASE_DIR/server ~/opt/bin/$COMMAND_NAME
	echo 'Adding ~/opt/bin to your PATH...'
	if [[ $(uname -s) == Darwin ]] ; then
		RC_FILE=~/.bash_profile
	else
		RC_FILE=~/.bashrc
	fi
	if grep /opt/bin $RC_FILE >/dev/null ; then
		echo '+--- NOTICE --------------------------------------------------------------'
		echo "| It looks like you are already referencing ~/opt/bin in your $RC_FILE"
		echo '| This script will not make any modifications, but in order to have access'
		echo "| to the '$COMMAND_NAME' command, make sure that ~/opt/bin is on your PATH"
		echo '+-------------------------------------------------------------------------'
	else
		echo "Appending to your PATH in $RC_FILE..."
		echo "# added by $BASE_DIR/setup.sh" >> $RC_FILE
		echo "export PATH=\"\$PATH:\"$HOME/opt/bin" >> $RC_FILE
	fi
fi

heading 'All Done!'
cat <<.
You should probably re-source your $RC_FILE in order to have access to the
'$COMMAND_NAME' command. You can run this command in your current session and
then be good to go:

    source $RC_FILE

Next steps:
- For a quick start, run the command to see all the available options:

    $COMMAND_NAME

- check out the documentation on GitHub or locally, located in $BASE_DIR

	- deployment_guide.md: for a walkthrough of deploying a spring-boot application
	- README.md:           for in depth documentation
	- faq.md:              for some frequently asked questions

Enjoy!
.
