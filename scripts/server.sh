#!/usr/bin/env bash

##############################################################################
# Entrypoint for the cli interface
#
# This script contains functions for general server management, and serves as
# the entrypoint to all the other scripts. Based on the arguments passed to it,
# it will either run the appropriate function, or load the necessary subcommand
# script.
##############################################################################


if [[ $_CODS_DEBUG == 1 ]] ; then
	logfile="cods-debug.log"
	echo >&2 "Started logging to $logfile"
	PS4='${BASH_SOURCE}::${FUNCNAME[0]}::$LINENO)'
	exec 99>$logfile
	BASH_XTRACEFD=99
	set -x
fi

auto_renew_certs() {
	if [[ -z $email ]] ; then
		echo 'It looks like you have not setup an email address. Please ensure you'
		echo "have one in $ENV_FILE before running this command."
		exit 1
	fi
	ssh -t $user@$ip email=$email "$(< $SCRIPTS/snippets/letsencrypt-cronjob.sh)"
	[[ $? -eq 0 ]] && echo 'Autorenewal enabled!'
}

show_ports() {
	ssh -qt $user@$ip "grep -woR '[0-9]\{4,\}' /etc/nginx/sites-available/ | awk -F: '{split(\$1, a, \"/\"); print \$2,a[5]}' | sort -nk1"
}

enable_swap() {
	ssh -t $user@$ip "
	set -e
	# setup swap file
	sudo fallocate -l 1G /swapfile
	sudo chmod 600 /swapfile
	sudo mkswap /swapfile
	sudo swapon /swapfile
	echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab >/dev/null
	"
	[[ $? -eq 0 ]] && echo 'Swapfile enabled!'
}

upload_file() {
	while [[ $# -gt 0 ]] ; do
		arg=$1 ; shift
		case $arg in
			-d|--destination) destination=$1 ; shift;;
			--destination=*) destination=${arg#*=};;
			-f|--file) file=$1 ; shift;;
			--file=*) file="${arg#*=}" ; file="${file/#\~/$HOME}";;
			*) echo "Unknown argument: $arg" ; exit 1;;
		esac
	done
    if [[ -z "$file" ]] ; then
		cat <<-.
		Upload a file to the server. Optionally specify a destination, otherwise
		will default to your home directory

		-f|--file <filepath>           -- path to the file to upload
		-d|--destination <destination> -- (optional) destination for the file on
		                                  the server

		Examples:
		    $(basename "$0") upload -f ~/Downloads/mycat.png -d /srv/example.com/public/uploads/mycat.png
		    $(basename "$0") upload --file=migration.sql
		    $(basename "$0") upload --file ~/IdeaProjects/blog/seeder.sql
		.
		die
    fi
	if [[ ! -e "$file" ]]; then
		echo "Error: $file not found!"
		exit 1
	fi

	scp -r "$file" "$user@$ip:$destination"
}

destroy_server() {
	cat <<-.
	This command will remove any knowledge this setup or your local machine has
	of the server. It will *not* remove the server from your VPS provider.

	*** IF YOU HAVE DATABASE BACKUPS, THIS WILL REMOVE THEM ***

	You might want to copy/move $DATA_DIR/db-backups

	Are you absolutely sure you want to do this?

	Type "destroy the server" to continue
	.
	IFS= read input
	if [[ "$input" != "destroy the server" ]] ; then
		die 'Aborting...'
	else
		echo 'Destroying...'
		rm -rfv "$DATA_DIR"
		rm -v "$BIN_PREFIX/$SCRIPT_NAME"
		echo "Removing $ip from ~/.ssh/known_hosts"
		sed -i .bak -e /^$ip/d "$HOME/.ssh/known_hosts"
	fi
}

restart_service() {
	while [[ $# -gt 0 ]] ; do
	    arg=$1 ; shift
	    case $arg in
			-s|--service) service=$1 ; shift;;
			--service=*) service=${arg#*=};;
			*) echo "Unknown argument: $arg" ; exit 1;;
	    esac
	done
	if [[ -z $service ]]; then
		cat <<-.
		Restart a service

		-s|--service <service> -- name of the service to restart

		Examples:
		    $(basename "$0") restart -s nginx
		    $(basename "$0") restart --service example.com
		.
		die
	fi
	ssh -t $user@$ip "sudo systemctl restart $service"
	[[ $? -eq 0 ]] && echo "$service restarted!"
}

add_sshkey() {
	while [[ $# -gt 0 ]] ; do
	    arg=$1 ; shift
	    case $arg in
	        -f|--sshkeyfile) sshkeyfile="$1" ; shift;;
	        --sshkeyfile=*) sshkeyfile="${arg#*=}" ; sshkeyfile="${sshkeyfile/#\~/$HOME}";;
	        *) echo "Unknown argument: $arg" ; exit 1;;
	    esac
	done
    if [[ -z "$sshkeyfile" ]] ; then
		cat <<-.
		Add an additional authorized ssh key to your account

		-f|--sshkeyfile <sshkeyfile> -- path to the public ssh key to add

		Examples:
		    $(basename "$0") addkey -f ~/.ssh/my-other-computer.pub
		    $(basename "$0") addkey --sshkeyfile ~/my-other-computer.pub
		.
		die
    fi
	if [[ ! -f "$sshkeyfile" && ! -r "$sshkeyfile" ]] ; then
		echo 'Please enter a valid ssh key file.'
		echo "$sshkeyfile does not exist or is not readable."
		exit 1
	fi

	cat "$sshkeyfile" | ssh $user@$ip 'cat >> .ssh/authorized_keys'
	[[ $? -eq 0 ]] && echo 'ssh key added!'
}

show_info() {
	if [[ $# -eq 0 ]] ; then
		cat <<-info
			Information about your server:

			Cods Version: $(head -n1 "$BASE_DIR/CHANGELOG.md")

			ip address: $ip
			user:       $user

			MySQL port: 3306
			ssh port:   22

			data directory:   $DATA_DIR
			database backups: $DATA_DIR/db-backups/
			command:          $0
			base directory:   $BASE_DIR
		info
	elif [[ $1 == ip ]] ; then
		echo $ip
	elif [[ $1 == user ]] ; then
		echo $user
	fi

}

show_usage() {
	cat <<-help_message
	$(basename "$0") -- command for server management
	usage

	    $(basename "$0") <command> [options]

	where <command> is one of the following:

	    site -- manage sites
	    db   -- manage databases
	    user -- manage users

	    login       -- login to the server
	    info        -- display information about the server
	    ports       -- show the ports that are being reverse proxied to
	    ping        -- ping the server
	    swapon      -- create and enable a swapfile (requires sudo password)
	    autorenew   -- setup https certs to be automatically renewed
	    reboot      -- reboot the server
	    run         -- run arbitrary commands (with a pty)
	    pipe        -- run arbitrary commands (without a pty)
	    credentials -- view server credentials (found in $DATA_DIR/credentials.txt)
	    destroy     -- destroy the server
	    tmux        -- attach to an existing, or create a new tmux session

	    switch-java-version -- switch the default version of java on the server
	    bash-completion     -- generate bash tab completion script

	    upload  -f <file> [-d <destination>]
	    restart -s <service>
	    addkey  -f <sshkeyfile>

	help_message
}

# find out where this script is located so we can be sure we're running
# everything from the correct location
SCRIPT_PATH="$0"
SCRIPT_NAME="$(basename "$SCRIPT_PATH")"
while [[ -L "$SCRIPT_PATH" ]] ; do # resolve symlinks
	SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
done
BASE_DIR="$( cd "$( dirname "$SCRIPT_PATH" )"/.. && pwd -P )"
BASE_DATA_DIR="$HOME/.config/cods"

DATA_DIR="$BASE_DATA_DIR/$SCRIPT_NAME"
ENV_FILE="$DATA_DIR/env.sh"
TEMPLATES="$BASE_DIR/templates"
SCRIPTS="$BASE_DIR/scripts"
SNIPPETS="$SCRIPTS/snippets"

source "$SCRIPTS/util.sh"
source "$ENV_FILE"
source "$BASE_DATA_DIR/config.sh"
# sanity check, make sure we have the values we need from the env file
if [[ ! -f "$ENV_FILE" || -z $user || -z $ip ]] ; then
	echo "It looks like the env file ($ENV_FILE) is not setup properly."
	die 'Are both `user` and `ip` set and not blank?'
fi

command=$1
shift

case $command in
	# sub commands
	site)      source "$SCRIPTS/site.sh";;
	db)        source "$SCRIPTS/db.sh";;
	user)      source "$SCRIPTS/user.sh";;

	# server managment
	login)     ssh $user@$ip;;
	upload)    upload_file "$@";;
	restart)   restart_service "$@";;
	reboot)    ssh -t $user@$ip 'sudo reboot';;
	info)      show_info "$@";;
	swapon)    enable_swap;;
	addkey)    add_sshkey "$@";;
	autorenew) auto_renew_certs;;
	ping)      ping -c5 $ip;;
	run)       ssh -t $user@$ip "umask 0002 && $@";;
	pipe)      ssh -T $user@$ip "$@";;
	root)      ssh -t $user@$ip "sudo -s";;
	ports)     show_ports;;
	tmux)      ssh -t $user@$ip 'tmux a || tmux';;
	destroy)   destroy_server;;

	switch-java-version)
		ssh -t $user@$ip sudo update-alternatives --config java
		;;

	credentials)
		case $1 in
			path) echo "$DATA_DIR/credentials.txt";;
			edit) $EDITOR "$DATA_DIR/credentials.txt";;
			add) shift ; echo "$@" >> "$DATA_DIR/credentials.txt";;
			*)
				if [[ ! -f "$DATA_DIR/credentials.txt" ]] ; then
					die "Error: $DATA_DIR/credentials.txt not found."
				fi
				cat "$DATA_DIR/credentials.txt" ;;
		esac ;;
	bash-completion)
		sed -e s/{{scriptname}}/$(basename "$0")/g "$SCRIPTS/bash_completion.sh"
		;;

	moo)
		echo ' ______'
		echo '< Moo! >'
		echo ' ------'
		echo '        \   ^__^'
		echo '         \  (oo)\_______'
		echo '            (__)\       )\/\'
		echo '                ||----w |'
		echo '                ||     ||'
		;;

	_test)
		source "$SCRIPTS/test.sh"
		;;

	*) show_usage;;
esac
