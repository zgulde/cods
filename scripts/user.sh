#!/usr/bin/env bash

##############################################################################
# Script for User Management
#
# This scripts contains functions to add and remove users on the server.
##############################################################################

add_user() {
	while [[ $# -gt 0 ]] ; do
		arg="$1" ; shift
		case $arg in
			-f|--sshkeyfile) sshkeyfile="$1" ; shift;;
			--sshkeyfile=*) sshkeyfile="${arg#*=}" ; sshkeyfile="${sshkeyfile/#\~/$HOME}";;
			-u|--username) new_user=$1 ; shift;;
			--username=*) new_user=${arg#*=};;
			--github-username) github_username=$1 ; shift;;
			--github-username=*) github_username=${arg#*=};;
			*) echo "Unknown argument: $arg" ; exit 1;;
		esac
	done
    if [[ -z $new_user || -z "$sshkeyfile" ]] && [[ -z $github_username ]] ; then
		cat <<-.
		Add a new admin user to the server. A password will be randomly
		generated for the new user.

		Can be used by either specifying a username and public key file, or a
		github username and the public keys will be extracted from github
		(https://github.com/\$USERNAME.keys)

		-f|--sshkeyfile <sshkeyfile>  -- path to the new user's public key
		-u|--username <username>      -- username for the new user
		--github-username <username>  -- github username to lookup public keys;
		                                 will also be used as server username

		Examples:
		    $(basename "$0") user add -u sally -f ~/sallys-ssh-key.pub
		    $(basename "$0") user add --username=sally --sshkeyfile=~/key.pub
		    $(basename "$0") user add --github-username gocodeup
		.
		die
    fi

	if [[ -n $github_username ]] ; then
		new_user=$github_username
		sshkeyfile=$(mktemp)
		trap "rm -f $sshkeyfile" EXIT
		url="https://github.com/${github_username}.keys"
		echo "- Downloading Ssh Key(s) for $github_username"
		curl --location --output "$sshkeyfile" "$url"
		if [[ $? -ne 0 ]] ; then
			echo "Error obtaining public keys for $github_username!"
			echo "$url gave a non-200 response."
			echo 'Aborting...'
			exit 1
		fi
		if [[ ! -s $sshkeyfile ]] ; then
			echo "Error! It looks like this user doesn't have any public keys tied to"
			echo "their github account. Check ($url)."
			echo 'Aborting...'
			exit 1
		fi
		echo 'Downloaded public ssh key(s)!'
	fi

	if [[ ! -f "$sshkeyfile" && ! -r "$sshkeyfile" ]]; then
		echo 'Please enter a valid ssh key file.'
		echo "$sshkeyfile does not exist or is not readable."
		exit 1
	fi

	password="$(mkpassword)"
	echo "Creating user ${new_user}... (enter *your* sudo password when prompted)"
	ssh -t $user@$ip "
	set -e
	sudo useradd --create-home --shell /bin/bash --groups sudo,web $new_user
	echo '$new_user:$password' | sudo chpasswd
	sudo mkdir -p /home/$new_user/.ssh
	cat <<< '$(cat "$sshkeyfile")' | sudo tee /home/$new_user/.ssh/authorized_keys >/dev/null
	sudo chown --recursive $new_user:$new_user /home/$new_user
	echo '$new_user ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo
	for site in /etc/nginx/sites-available/* ; do
		site=\$(basename \$site)
		site=\${site//./-}
		[[ \$site == default ]] && continue
		sudo usermod -a -G \$site $new_user
	done
	"
	if [[ $? -ne 0 ]] ; then
		echo 'Uh oh, something went wrong! Check the output for details.'
		exit 1
	fi

	echo "User ${new_user}: $password" >> "$DATA_DIR/credentials.txt"
	cat <<-.
	User ${new_user} created!
	Password for ${new_user}: ${password}
	[NOTICE] credentials for ${new_user} have been added to $DATA_DIR/credentials.txt
	You can view the password again for the user by running the 'credentials'
	subcommand.
	You may wish to share this password with your teammate now.
	.
}

remove_user() {
	local username
	while [[ $# -gt 0 ]] ; do
		arg="$1" ; shift
		case $arg in
			-u|--username) username=$1 ; shift;;
			--username=*) username=${arg#*=};;
			*) echo "Unknown argument: $arg" ; exit 1;;
		esac
	done

	if [[ -z $username ]] ; then
		cat <<-.
		Remove a user from the server

		-u|--username <username> -- username of the user to remove

		Examples:
		    $(basename $0) user remove --username sally
		.

		exit 1
	fi

	# TODO: first check if user exists
	ssh $user@$ip "
	if ! id $username >/dev/null 2>&1 ; then
		echo 'Error: user $username not found.'
		exit 1
	fi
	sudo userdel --force --remove $username
	sudo EDITOR='sed -i /^$username/d' visudo
	"
	[[ $? -eq 0 ]] && echo "$username removed!"
}

show_usage() {
	cat <<-.
	user -- command for managing users
	usage

	    $(basename "$0") user <command> [options]

	where <command> is one of the following:

	    add     -f <sshkeyfile> -u <username> --github-username <ghusername>
	    remove  -u <username>
	.
}

command=$1
shift

case $command in
	add) add_user "$@";;
	rm|remove) remove_user "$@";;
	*) show_usage;;
esac
