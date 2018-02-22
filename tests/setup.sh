heading 'Testing Initial Setup'

logfile="$BASE_DIR/testing.log"

ssh -T $user@$ip sudo bash >/dev/null <<test
fail() { echo -e "  \\033[01;31m[FAIL]\\033[0m \$@" >&2 ; }

id -u tomcat >/dev/null || fail 'Expected to find a user account for tomcat'
[[ \$(getent passwd tomcat | cut -d: -f7) == /bin/false ]] ||\
	fail 'Expected tomcat users shell to be /bin/false'

stat=\$(stat --format='%G:%U' /opt/tomcat)
[[ \$stat == tomcat:tomcat ]] || fail 'Expected permissions to be set on /opt/tomcat'
[[ -z "\$(ls -A /opt/tomcat/webapps)" ]] ||\
	fail "Expected webapps dir to be empty. Found '\$(ls -A /opt/tomcat/webapps)'"
grep -F '<!--## Virtual Hosts ##-->' /opt/tomcat/conf/server.xml >/dev/null ||\
	fail 'Expected to find marker for virtual hosts in server.xml'
[[ -f /etc/systemd/system/tomcat.service ]] || fail 'Expected to find tomcat service'
systemctl list-unit-files | grep enabled | grep tomcat >/dev/null ||\
	fail 'Expected tomcat service to be enabled'
systemctl | grep running | grep -F tomcat.service >/dev/null ||\
	fail 'Expected tomcat service to be running'

systemctl list-unit-files | grep enabled | grep nginx >/dev/null ||\
	fail 'Expected nginx service to be enabled'
systemctl | grep running | grep -F nginx.service >/dev/null ||\
	fail 'Expected nginx service to be running'
[[ -z "\$(ls -A /var/www)" ]] ||\
	fail "Expected nginx dir to be empty. Found '\$(ls -A /var/www)'"
egrep 'return\s*444;' /etc/nginx/sites-available/default ||\
	fail 'Expected default nginx config to be setup'

getent group git >/dev/null || fail 'Expected "git" group to exist'
[[ \$(stat --format='%a' /srv) == 2775 ]] ||\
	fail 'Expected permissions to be set on /srv'
[[ \$(stat --format='%G' /srv) == git ]] ||\
	fail 'Expected /srv to belong to the "git" group'

[[ -f /etc/tmpfiles.d/home.conf ]] ||\
	fail 'Expected to find tmpfiles configuration in /etc'

id -u $user >/dev/null || fail 'Expected to find a user account for $user'
test

echo '[DONE]'
