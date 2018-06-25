heading 'Testing Initial Setup'

logfile="$BASE_DIR/testing.log"

ssh -T $user@$ip sudo bash >/dev/null <<test
fail() { echo -e "  \\033[01;31m[FAIL]\\033[0m \$@" >&2 ; }

systemctl list-unit-files | grep enabled | grep nginx >/dev/null ||\
	fail 'Expected nginx service to be enabled'
systemctl | grep running | grep -F nginx.service >/dev/null ||\
	fail 'Expected nginx service to be running'
[[ -z "\$(ls -A /var/www)" ]] ||\
	fail "Expected nginx dir to be empty. Found '\$(ls -A /var/www)'"
egrep 'return\s*444;' /etc/nginx/sites-available/default ||\
	fail 'Expected default nginx config to be setup'

getent group web >/dev/null || fail 'Expected "web" group to exist'
[[ \$(stat --format='%a' /srv) == 2775 ]] ||\
	fail 'Expected permissions to be set on /srv'
[[ \$(stat --format='%G' /srv) == web ]] ||\
	fail 'Expected /srv to belong to the "web" group'

[[ -f /etc/tmpfiles.d/home.conf ]] ||\
	fail 'Expected to find tmpfiles configuration in /etc'

id -u $user >/dev/null || fail 'Expected to find a user account for $user'
test

echo '[DONE]'
