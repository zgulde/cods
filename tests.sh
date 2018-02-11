#!/bin/bash

# find out where this script is located so we can be sure we're running
# everything from the correct location
SCRIPT_PATH=$0
while [[ -L $SCRIPT_PATH ]] ; do # resolve symlinks
	SCRIPT_PATH="$(readlink $SCRIPT_PATH)"
done
BASE_DIR="$( cd "$( dirname "$SCRIPT_PATH" )" && pwd )"

ENV_FILE="$BASE_DIR/.env"
TEMPLATES="$BASE_DIR/templates"
SCRIPTS="$BASE_DIR/scripts"
SNIPPETS="$SCRIPTS/snippets"

if [[ ! -f $ENV_FILE ]]; then
	echo 'No .env file found!'
	echo 'Running initial setup...'
	source $SCRIPTS/setup.sh
	exit
fi

source $SCRIPTS/util.sh
source $ENV_FILE

##############################################################################

echo 'testing valid_username function...'

valid_usernames=( zach aA1234_09 codeup a )
invalid_usernames=( Zach '' Abcd A 'a!@#' 123 root )

for username in ${valid_usernames[*]} ; do
	valid_username $username || die "Expected username: '${username}' to be valid"
done

for username in ${invalid_usernames[*]} ; do
	valid_username $username && die "Expected username: '${username}' to be invalid"
done

echo '[PASS]'

echo 'testing mkpassword function...'

password=$(mkpassword 4)
if [[ ${#password} -ne 4 ]] ; then
	die 'Expected "$(mkpassword 4)" to have a length of 4'
fi
password=$(mkpassword 24)
if [[ ${#password} -ne 24 ]] ; then
	die 'Expected "$(mkpassword 24)" to have a length of 24'
fi
if [[ $password =~ [^a-zA-Z0-9] ]] ; then
	die "Found unexpected non-alphanumeric character in password: '$password'"
fi

echo '[PASS]'

echo 'testing confirm function...'

nos=( no n N anythingelse '' No es )
yesses=( y Y yes Yes YES )

for no in ${nos[*]} ; do
	if confirm <<< "$no" ; then
		die "Expected confirm to return false for input '$no'"
	fi
done

for yes in ${yesses[*]} ; do
	if ! confirm <<< "$yes" ; then
		die "Expected confirm to be true for input '$yes'"
	fi
done

echo '[PASS]'

echo 'testing die function'

message='some message'
output=$(die $message)
rc=$?
[[ $rc -eq 0 ]] && die 'Expected die to exit with a non-zero return code'
[[ $output == $message ]] || die 'Expected die to display passed message'

echo '[PASS]'
