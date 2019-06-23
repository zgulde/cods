#!/bin/bash

TESTS="$BASE_DIR/tests"

if [[ ! -d $TESTS ]] ; then
	echo "$TESTS not found!"
	echo 'This command is used to run automated tests on the server setup, and'
	echo 'is meant only to be used during development of the cods tool.'
	exit 1
fi

if [[ ! -f $ENV_FILE ]]; then
	echo 'No env file found!'
	echo 'Currently we can only test everything with an already setup environment.'
	echo 'exiting...'
	exit 1
fi

source $ENV_FILE
source $SCRIPTS/util.sh

command=$1 ; shift

case $command in
	util)  source $TESTS/util.sh;;
	site)  source $TESTS/site.sh;;
	setup) source $TESTS/setup.sh;;
	deploy) source $TESTS/deploy.sh;;
	all)
		source $TESTS/util.sh
		source $TESTS/setup.sh
		source $TESTS/site.sh
		source $TESTS/deploy.sh
		;;
	_sudo)
		# Enable passwordless sudo
		# Intentionally undocumented, as we probably don't want end users doing
		# this, but for running the automated tests, this is the only sane way
		# to do things, as almost everything we want to test requires a sudo
		# password multiple times.
		ssh -t $user@$ip "echo '$user ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo"
		;;

	* ) echo 'util | site | setup | deploy';;
esac
