#!/usr/bin/env bash

if [[ $_CODS_DEBUG == 1 ]] ; then
	logfile="cods-debug.log"
	echo >&2 "Started logging to $logfile"
	PS4='${BASH_SOURCE}::${FUNCNAME[0]}::$LINENO)'
	exec 99>$logfile
	BASH_XTRACEFD=99
	set -x
fi

usage() {
	cat <<-.
	$(basename "$0") -- This command is for creating new server commands, *not*
	                  for interacting with a server directly
	Version: $(head -n1 "$BASE_DIR/CHANGELOG.md")

	Commands:

	help: Open the interactive help

	init:  Initialize a new server. -- You must provide a name for the new
	                                   server, this name will be the name of
	                                   the command that is created.

	add: Add an existing server -- You will need to have ssh access to the
	                               server, and provide a name for the new
	                               server command

	update: Update all the existing already setup server commands

	list: Show all the server commands that are setup as well as all the sites
	      that are setup on each server

	Examples:
	    $(basename "$0") init myserver
	    $(basename "$0") init my-awesome-server

	    $(basename "$0") add shared-server
	    $(basename "$0") add some-project-server

	    $(basename "$0") update

	    $(basename "$0") list

	    $(basename "$0") help
	.
	exit 1
}

show_server_path() {
	echo "$SCRIPTS/server.sh"
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
BASE_DIR="$(dirname "$(dirname "$SCRIPT_PATH")")"
SCRIPTS=$BASE_DIR/scripts
BASE_DATA_DIR="$HOME/.config/cods"

if [[ ! -f "$BASE_DATA_DIR/config.sh" ]] ; then
	mkdir -p "$BASE_DATA_DIR"
	cat > "$BASE_DATA_DIR/config.sh" <<-.
	BIN_PREFIX=/usr/local/bin
	.
fi

source "$BASE_DATA_DIR/config.sh"
source "$SCRIPTS/util.sh"

logo=(
	"(C)(O)deup (D)eployment (S)cripts"
	"Version: $(head -n1 "$BASE_DIR/CHANGELOG.md")"
	''
	' _______  _______  ______   _______'
	'(  ____ \(  ___  )(  __  \ (  ____ \'
	'| (    \/| ( d ) || ( e\  )| (   \/'
	'| |      | | e | || | p ) || (_____'
	'| |      | | u | || | l | |(_____  )'
	'| |      | | p | || | o ) | ment ) |'
	'| (_ __/\| (___) || (_y/  )/\____) | cripts'
	'(_______/(_______)(______/ \_______)'
	''
)

subcommand=$1 ; shift

case $subcommand in
	help) source "$SCRIPTS/interactive-help.sh";;
	banner|logo)
		for line in "${logo[@]}" ; do
			echo "$line"
			sleep 0.3
		done
		;;
	update)
		for server_command in $(ls -d "$BASE_DATA_DIR"/*/) ; do
			server_command="${server_command%/}"
			server_command="${server_command##*/}"
			echo "- Updating $server_command"
			echo "  Linking $BIN_PREFIX/$server_command To $(show_server_path)..."
			rm "$BIN_PREFIX/$server_command"
			ln -s "$(show_server_path)" "$BIN_PREFIX/$server_command"
		done
		echo '- All Done!'
		;;
	init)
		[[ -z $1 ]] && usage
		COMMAND_NAME="$1" ; shift
		if [[ -L "$BIN_PREFIX/$COMMAND_NAME" ]] || which "$COMMAND_NAME">/dev/null 2>&1 ; then
			echo "$COMMAND_NAME already exists!"
			echo 'Choose another name, or rename/delete the existing command.'
			exit 1
		fi

		DATA_DIR="$BASE_DATA_DIR/$COMMAND_NAME"
		ENV_FILE="$DATA_DIR/env.sh"
		mkdir -p "$DATA_DIR/db-backups"

		while [[ $# -gt 0 ]] ; do
		    arg=$1 ; shift
		    case $arg in
				-i|--ip) export ip=$1 ; shift;;
				--ip=*) export ip=${arg#*=};;
				-u|--user) export user=$1 ; shift;;
				--user=*) export user=${arg#*=};;
				-e|--email) export email=$1 ; shift;;
				--email=*) export email=${arg#*=};;
				--root-user) export root_user=$1 ; shift;;
				--root-user=*) export root_user=${arg#*=};;
		        *) echo "Unknown argument: $arg" ; exit 1;;
		    esac
		done

		if [[ -z $root_user ]] ; then
			export root_user=root
		fi

		source "$BASE_DIR/scripts/setup.sh"
		;;
	add)
		[[ -z $1 ]] && usage
		COMMAND_NAME="$1" ; shift
		if [[ -L "$BIN_PREFIX/$COMMAND_NAME" ]] || which $COMMAND_NAME >/dev/null 2>&1 ; then
			echo "$COMMAND_NAME already exists in $BIN_PREFIX"
			echo 'Choose another name, or rename/delete the existing command.'
			exit 1
		fi

		while [[ $# -gt 0 ]] ; do
		    arg=$1 ; shift
		    case $arg in
		        -i|--ip) ip=$1 ; shift;;
		        --ip=*) ip=${arg#*=};;
				-u|--user) user=$1 ; shift;;
				--user=*) user=${arg#*=};;
		        *) echo "Unknown argument: $arg" ; exit 1;;
		    esac
		done

		if [[ -z $ip ]] ; then
			read -p "- Enter the server's ip address: " ip
		fi
		if [[ -z $user ]] ; then
			read -p "- Enter your username: " user
		fi

		if ! ssh $user@$ip true ; then
			echo "Unable to login! Command: ssh $user@$ip true"
			echo 'Make sure you have access to the server and have the correct'
			echo 'username and ip address.'
			exit 1
		fi
		ln -s "$(show_server_path)" "$BIN_PREFIX/$COMMAND_NAME"
		DATA_DIR="$BASE_DATA_DIR/$COMMAND_NAME"
		ENV_FILE="$DATA_DIR/env.sh"
		mkdir -p "$DATA_DIR/db-backups"
		echo "ip=$ip" >> "$ENV_FILE"
		echo "user=$user" >> "$ENV_FILE"
		touch "$DATA_DIR/credentials.txt"
		echo "- All done!"
		echo "  '$COMMAND_NAME' ready to go!"
		;;
	_server|path) show_server_path;;
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
	list|ls)
		for server_dir in $(ls -d "$BASE_DATA_DIR"/*/) ; do
			server_command="$(basename $server_dir)"
			echo "--- $server_command"
			$server_command site ls
		done
		;;
	*) usage;;
esac
