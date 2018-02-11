source $SCRIPTS/util.sh

echo 'testing valid_username function...'

valid_usernames=( zach aA1234_09 codeup a )
invalid_usernames=( Zach '' Abcd A 'a!@#' 123 root )

for username in ${valid_usernames[*]} ; do
	valid_username $username || fail "Expected username: '${username}' to be valid"
done

for username in ${invalid_usernames[*]} ; do
	valid_username $username && fail "Expected username: '${username}' to be invalid"
done

echo '[PASS]'

echo 'testing mkpassword function...'

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

echo '[PASS]'

echo 'testing confirm function...'

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

echo '[PASS]'

echo 'testing die function'

message='some message'
output=$(die $message)
rc=$?
[[ $rc -eq 0 ]] && fail 'Expected die to exit with a non-zero return code'
[[ $output == $message ]] || fail 'Expected die to display passed message'

echo '[PASS]'

