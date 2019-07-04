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
	* ) echo 'util | site | setup | deploy';;
esac
