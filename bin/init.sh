#!/bin/bash

usage() {
	cat <<-.
	$(basename $0) -- This command is for creating new server commands, *not*
	                  for interacting with a server directly

	Commands:

	init:  Initialize a new server. -- You must provide a name for the new
	                                   server, this name will be the name of
	                                   the command that is created.

	share: Add a shared server -- You will need to have ssh access to the
	                              server, and provide a name for the shared
	                              server command

	update -- Update all the existing already setup server commands

	Examples:
	    $(basename $0) init myserver
	    $(basename $0) init my-awesome-server

	    $(basename $0) share shared-server
	    $(basename $0) share some-project-server

	    $(basename $0) update
	.
	exit 1
}

show_server_path() {
	echo "$BASE_DIR/server"
}

# find out where this script is located so we can be sure we're running
# everything from the correct location
SCRIPT_PATH="$0"
# I'd really rather not do this with python, but we need to find the
# installation location if this script is symlinked, and this is the only way
# that works between both MacOS and (probably most) Linuxes (assuming a python).
# The inline python code does work on both python2 and python3
which python >/dev/null && PYTHON=python || PYTHON=python3
SCRIPT_PATH="$($PYTHON -c "import os; print(os.path.realpath('$SCRIPT_PATH'))")"
BASE_DIR="$(dirname "$(dirname $SCRIPT_PATH)")"
SCRIPTS=$BASE_DIR/scripts

source $SCRIPTS/util.sh

case $1 in
	update)
		for server_command in $(ls -d ~/.cods/*/) ; do
			server_command="${server_command%/}"
			server_command="${server_command##*/}"
			rm /usr/local/bin/$server_command
			ln -s "$(show_server_path)" /usr/local/bin/$server_command
		done
		;;
	init)
		[[ -z $2 ]] && usage
		COMMAND_NAME="$2"
		if [[ -L /usr/local/bin/$COMMAND_NAME ]] ; then
			echo "$COMMAND_NAME already exists in /usr/local/bin"
			echo 'Choose another name, or rename/delete the existing command.'
			exit 1
		fi

		DATA_DIR="$HOME/.cods/$COMMAND_NAME"
		ENV_FILE="$DATA_DIR/env.sh"
		mkdir -p $DATA_DIR/db-backups
		source $BASE_DIR/scripts/setup.sh
		;;
	share)
		[[ -z $2 ]] && usage
		COMMAND_NAME="$2"
		if [[ -L /usr/local/bin/$COMMAND_NAME ]] ; then
			echo "$COMMAND_NAME already exists in /usr/local/bin"
			echo 'Choose another name, or rename/delete the existing command.'
			exit 1
		fi

		read -p "Enter the server's ip address: " ip
		read -p "Enter your username: " user
		if ! ssh $user@$ip true ; then
			echo "Unable to login! Command: ssh $user@$ip true"
			echo 'Make sure you have access to the server and have the correct'
			echo 'username and ip address.'
			exit 1
		fi
		ln -s $BASE_DIR/server /usr/local/bin/$COMMAND_NAME
		DATA_DIR="$HOME/.cods/$COMMAND_NAME"
		ENV_FILE="$DATA_DIR/env.sh"
		mkdir -p $DATA_DIR/db-backups
		echo "ip=$ip" >> $ENV_FILE
		echo "user=$user" >> $ENV_FILE
		touch $DATA_DIR/credentials.txt
		echo "All done! '$COMMAND_NAME' ready to go!"
		;;
	_server) show_server_path;;
	*) usage;;
esac

