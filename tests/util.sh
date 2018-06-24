source $SCRIPTS/util.sh

heading 'Testing Utility Functions'

number_failures=0

success() { echo -e "\r\033[01;32m$@\033[0m                      " ; }

fail() {
	[[ $number_failures -eq 1 ]] && echo
	echo -e "  \033[01;31m[FAIL]\033[0m $@" >&2
	((++number_failures))
}

echo -n '[TESTING] valid_username...'

valid_usernames=( zach aA1234_09 codeup a )
invalid_usernames=( Zach '' Abcd A 'a!@#' 123 root )

for username in ${valid_usernames[*]} ; do
	valid_username $username || fail "Expected username: '${username}' to be valid"
done

for username in ${invalid_usernames[*]} ; do
	valid_username $username && fail "Expected username: '${username}' to be invalid"
done

[[ $number_failures -eq 0 ]] && success '[PASSED] valid_username'

echo -n '[TESTING] mkpassword...'
number_failures=0

password=$(mkpassword 4)
if [[ ${#password} -ne 4 ]] ; then
	fail 'Expected "$(mkpassword 4)" to have a length of 4'
fi
password=$(mkpassword 24)
if [[ ${#password} -ne 24 ]] ; then
	fail 'Expected "$(mkpassword 24)" to have a length of 24'
fi
if [[ $password =~ [^a-zA-Z0-9] ]] ; then
	fail "Found unexpected non-alphanumeric character in password: '$password'"
fi

[[ $number_failures -eq 0 ]] && success '[PASSED] mkpassword'

echo -n '[TESTING] confirm...'
number_failures=0

nos=( no n N anythingelse '' No es )
yesses=( y Y yes Yes YES )

for no in ${nos[*]} ; do
	if confirm <<< "$no" ; then
		fail "Expected confirm to return false for input '$no'"
	fi
done

for yes in ${yesses[*]} ; do
	if ! confirm <<< "$yes" ; then
		fail "Expected confirm to be true for input '$yes'"
	fi
done

[[ $number_failures -eq 0 ]] && success '[PASSED] confirm'

echo -n '[TESTING] die...'
number_failures=0

message='some message'
output=$(die $message)
rc=$?
[[ $rc -eq 0 ]] && fail 'Expected die to exit with a non-zero return code'
[[ $output == $message ]] || fail 'Expected die to display passed message'

[[ $number_failures -eq 0 ]] && success '[PASSED] die'

echo -n '[TESTING] repeat...'
number_failures=0

if [[ "$(repeat 1 3)" != 111 ]] ; then
	fail 'Expected $(repeat 1 3) === 111'
fi

[[ $number_failures -eq 0 ]] && success '[PASSED] repeat'
