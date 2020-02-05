##############################################################################
# First time setup script
#
# This script will be invoked from the `cods init` command. It will perform all
# the first time setup, as well as run the provision script on the server
##############################################################################

# check for the utilities we'll need
# these should be available on a default osx install
prereqs=(perl dig ssh scp curl)
for tool in ${prereqs[@]}; do
	which $tool >/dev/null
	if [[ $? -ne 0 ]]; then
        echo "Error: couldn't find $tool."
		echo "Please install '$tool' before continuing."
		exit 1
	fi
done

heading(){
	echo '----------------------------------'
	echo "> $@"
	echo '----------------------------------'
}

if [[ -e "$ENV_FILE" ]]; then
	echo 'It looks like things are already setup, aborting...'
	echo 'To redo the setup process, try running the "destroy" subcommand.'
	echo "Alternatively, remove $ENV_FILE"
	exit 1
fi

echo '- IP Address'
if [[ -z $ip ]] ; then
	read -p $'\n  Enter the servers ip address: ' ip
else
	echo "  using ip address $ip"
fi
echo

if ! grep -q "^$ip" ~/.ssh/known_hosts ; then
	echo '  Since this will be the first time we will have connected to your server,'
	echo '  you will be prompted whether or not you trust the server. Type yes when'
	echo '  prompted.'
	echo
fi

# make sure we can access that server
ssh $root_user@$ip ls > /dev/null
if [[ $? -ne 0 ]]; then
	echo "Error: Cannot login to $ip!"
	echo 'Make sure:'
	echo '  - The ip address is correct'
	echo '  - Your public key is on the server'
	echo '  - The server is "fresh" (not setup manually or by another tool)'
	echo 'and try again.'
	exit 1
fi

echo '- Username'
if [[ -z $user ]] ; then
	echo
	echo '  You will need to now choose a username for the server. This is the user'
	echo '  you will log in as, as well as the database administrator user that'
	echo '  will be setup.'
	echo
	echo '  A username should start with a lowercase letter, and only consist of'
	echo '  lowercase letters, numbers, or the "_" character. It should also'
	echo '  be no longer than 30 characters.'
	echo '  Specifically: /^[a-z][a-z0-9_]{0,29}$/'
	echo
	echo '  Usually it is fine (and easier) to use the same username as the one on'
	echo '  your local machine, but if your local username does not match the given'
	echo '  rules, you should choose something different.'
	echo
	read -p "  Enter a username (default $USER): " user
	if [[ -z "$user" ]]; then
		user=$USER
	fi
fi
echo "  using username '$user'"

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

echo "- Email Address"
if [[ -z $email ]] ; then
	echo
	echo '  We will need an email address for obtaining a https certificate, while this'
	echo '  is optional, it is recommended so that you can be contacted if anything'
	echo '  goes wrong with your site.'
	echo
	read -p 'email: ' email
else
	echo "  using email: $email"
fi
echo

echo '- Autogenerate Passwords'
password="$(mkpassword)"
db_password="$(mkpassword)"

echo "  Here are your auto-generated passwords for the server:"
echo
echo "  Sudo Password: $password" | tee -a "$DATA_DIR/credentials.txt"
echo "  DB Password:   $db_password" | tee -a "$DATA_DIR/credentials.txt"
echo
echo "  These have been saved to $DATA_DIR/credentials.txt, and will be accessible"
echo "  through your server command once the setup process is complete."
echo
echo '  Next, we will provision the server. Please be patient, as this process'
echo '  can take a few minutes.'
echo
echo '  The server will be setup using the values below:'
echo
echo "  - ip: $ip"
echo "  - username: $user"
echo "  - email: $email"
echo
read -p 'Press <Enter> to continue and setup the server or Ctrl-C to exit.'

# create the env file
cat > "$ENV_FILE" <<EOF
ip=$ip
user=$user
email=$email
EOF

echo "$ENV_FILE file created!"

heading 'running provision script'

ssh $root_user@$ip bash < "$SCRIPTS/provision.sh"

# make sure provisioning went okay
if [[ $? -ne 0 ]]; then
	rm -rf "$DATA_DIR"
	echo
	echo 'Uh oh! Looks like something went wrong with the server provisioning!'
	echo
	echo 'Check the above output for more details.'
	echo
	echo 'To re-provision, you should:'
	echo '  1. Re-image your server'
	echo "  2. Remove the $BASE_DATA_DIR/$COMMAND_NAME directory"
	echo '  3. Edit "~/.ssh/known_hosts" and remove the entry for the servers ip'
	echo '  4. Run the init script again'
	echo
	exit 1
fi

heading 'Copying over templates'

scp -r "$BASE_DIR/templates" $root_user@$ip:/srv/.templates

heading 'securing mysql installation...'

# secure the mysql install
ssh $root_user@$ip 'mysql -u root' <<sql
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

ssh $root_user@$ip bash <<setup_user
# create a user and add the ssh key
useradd --create-home --shell /bin/bash --groups sudo,web $user
echo '$user:$password' | chpasswd
# copy over ssh key config for the new user
mkdir -p /home/$user/.ssh
cp \$HOME/.ssh/authorized_keys /home/$user/.ssh/
chown --recursive $user:$user /home/$user/.ssh
# allow passwordless sudo
echo '$user ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo

# disable password login + root login
perl -i -pe 's/(PasswordAuthentication\s*)yes/\1no/' /etc/ssh/sshd_config
perl -i -pe 's/(PermitRootLogin\s*)yes/\1no/' /etc/ssh/sshd_config
service sshd restart
service ssh restart
setup_user

[[ $? -eq 0 ]] && echo 'User created and ssh locked down!'

heading 'Finsihed Server Provisioning!'

heading "Setting up '$COMMAND_NAME' command..."

echo "Linking $BIN_PREFIX/$COMMAND_NAME to $BASE_DIR/scripts/server.sh..."
ln -s "$BASE_DIR/scripts/server.sh" "$BIN_PREFIX/$COMMAND_NAME"

heading 'All Done!'

cat <<.

- For a quick start, run the command to see all the available options:

    $COMMAND_NAME

Enjoy!
.
