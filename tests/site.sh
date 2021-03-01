heading "Testing site commands..."

eval "$(< $SCRIPTS/site.sh)" >/dev/null

( create_site > /dev/null ) && fail 'It should exit with a non-zero status when invoked with no arguments'

( create_site --domain > /dev/null ) &&\
	fail 'It should exit with a non-zero status when a domain is not specified'
( create_site --domain test.com > /dev/null ) &&\
	fail 'It should exit with a non-zero status when a site type is not specified'
( create_site --domain test.com --java > /dev/null ) &&\
	fail 'It should exit with a non-zero status when port is not specified for a java site'
( create_site --domain test.com --node > /dev/null ) &&\
	fail 'It should exit with a non-zero status when port is not specified for a node site'
( create_site --domain test.com --python > /dev/null ) &&\
	fail 'It should exit with a non-zero status when port is not specified for a python site'
( create_site --domain test.com --static --java --port 8080 > /dev/null ) &&\
	fail 'It should exit with a non-zero status when multiple types are specified'
( create_site --domain test.com --static --java --port 1023 > /dev/null ) &&\
	fail 'It should exit with a non-zero status when a port number too low (< 1024) is specified'
( create_site --domain test.com --static --java --port 65536 > /dev/null ) &&\
	fail 'It should exit with a non-zero status when a port number too high (> 65535) is specified'

echo '[TESTING] Java Site Creation'
echo -n '  Creating test site...'
create_site --domain test.com --java --spring-boot --force --port 12345
echo '  Finished creating test site.'

echo -n '  Running tests...'
ssh -T $user@$ip sudo bash >/dev/null <<'test'
fail() { echo -e "  \033[01;31m[FAIL]\033[0m $@" >&2 ; }

id -u test-com >/dev/null || fail 'Expected to find a user account for the site'
[[ $(getent passwd test-com | cut -d: -f7) == /bin/false ]] ||\
	fail 'Expected test.com users shell to be /bin/false'

[[ -d /srv/test.com/ ]] ||\
	fail 'Expected to find a directory created in /srv'
stat=$(stat --format='%G:%U' /srv/test.com)
[[ $stat == 'test-com:test-com' ]] ||\
	fail 'Expected /srv/test.com to be owned by "test.com:test.com"'
[[ -d /srv/test.com/public ]] ||\
	fail 'Expected to find a public directory for the site'
stat=$(stat --format='%G' /srv/test.com/public)
[[ $stat == 'test-com' ]] ||\
	fail "Expected the public directory to be owned by 'test.com' group, found '$stat'"
[[ -f /etc/nginx/sites-available/test.com ]] ||\
	fail 'Expected /etc/nginx/sites-available/test.com to exist'
[[ -L /etc/nginx/sites-enabled/test.com ]] ||\
	fail 'Expected /etc/nginx/sites-enabled/test.com to be a symlink'
[[ $(readlink /etc/nginx/sites-enabled/test.com) == /etc/nginx/sites-available/test.com ]] ||\
	fail 'Expected a link to the config file in sites-enabled from sites-available'
# make sure we used the right template
(
	grep proxy_pass /etc/nginx/sites-available/test.com &&\
	egrep 'listen\s*80;' /etc/nginx/sites-available/test.com &&\
	egrep 'server_name\s*test.com' /etc/nginx/sites-available/test.com
) >/dev/null || fail 'Expected to nginx config to be setup correctly'

[[ -f /srv/test.com/cods-config ]] || fail 'Expected to find a cods-config file for test.com'
(
	grep '^source=application.properties$' /srv/test.com/cods-config &&\
	grep '^destination=src/main/resources/application.properties$' /srv/test.com/cods-config
) >/dev/null || fail 'Expected to find cods-config file pre-modified for a spring-boot app'

[[ -d /srv/test.com/repo.git ]] || fail 'Expected to find a repository for test.com'
[[ -x /srv/test.com/repo.git/hooks/post-receive ]] ||\
	fail 'Expected to find an executable post-receive hook'

[[ -f /etc/systemd/system/test.com.service  ]] ||\
	fail 'Expected to find a service file setup'
grep 'java -jar app.jar' /etc/systemd/system/test.com.service ||\
	fail 'Excepted to find "java -jar app.jar" in the service unit'
grep 'User=test-com' /etc/systemd/system/test.com.service ||\
	fail 'Expected the service to run as user test-com'
grep 'Group=test-com' /etc/systemd/system/test.com.service ||\
	fail 'Expected the service to run as group test-com'
systemctl list-unit-files | grep enabled | grep test.com >/dev/null ||\
	fail 'Expected the service for test.com to be enabled'

systemctl | grep running | grep -F test.com.service >/dev/null &&\
	fail 'Expected the test.com service *not* to be running'

test -f /etc/sudoers.d/test-com ||\
	fail 'Expected to find configuration in /etc/sudoers.d/'
test
echo ' done.'

# echo '[DEBUG] Exiting early, leaving site intact'
# exit 0

echo -n '  Cleaning up...'
remove_site --domain test.com --force
echo ' ok.'

echo -n '[TESTING] Site was removed properly...'
ssh -T $user@$ip >/dev/null <<'.'
fail() { echo -e "  \033[01;31m[FAIL]\033[0m $@" >&2 ; }

[[ -d /srv/test.com ]] && fail 'Expected directory in /srv to be cleaned up'
[[ -L /etc/nginx/sites-enabled/test.com ]] &&\
	fail 'expected the symlink in sites-enabled to be removed'
[[ -f /etc/nginx/sites-available/test.com ]] &&\
	fail 'expected the nginx config in /etc/nginx/sites-available to be removed'
[[ -f /etc/systemd/system/test.com.service ]] &&\
	fail 'expected service file to be removed'
[[ -f /etc/sudoers.d/test-com ]] &&\
	fail 'expected sudoers config to be removed'
.
echo ' done.'

echo '[TESTING] Static Site Creation'
echo -n '  Creating site...'
create_site --domain test.com --static --force
echo ' ok.'
echo -n '  Running tests...'

ssh -T $user@$ip >/dev/null <<'test'
fail() { echo -e "  \033[01;31m[FAIL]\033[0m $@" >&2 ; }

[[ -d /srv/test.com ]] ||\
	fail 'Expected a directory in /srv to be created'
[[ -d /srv/test.com/public ]] ||\
	fail 'Expected a public directory to be created'
stat=$(stat --format='%G' /srv/test.com/public)
[[ $stat == 'test-com' ]] ||\
	fail "Expected public directory to be owned by group test.com, instead found $stat"
[[ -f /etc/nginx/sites-available/test.com ]] ||\
	fail 'Expected /etc/nginx/sites-available/test.com to exist'
[[ -L /etc/nginx/sites-enabled/test.com ]] ||\
	fail 'Expected /etc/nginx/sites-enabled/test.com to be a symlink'
[[ $(readlink /etc/nginx/sites-enabled/test.com) == /etc/nginx/sites-available/test.com ]] ||\
	fail 'Expected a link to the config file in sites-enabled from sites-available'
# make sure we used the right template
grep proxy_pass /etc/nginx/sites-available/test.com >/dev/null &&\
	fail 'Expected not to find "proxy_pass" in nginx site config'
egrep 'listen\s*443;' /etc/nginx/sites-available/test.com >/dev/null &&\
	fail 'Expected not to find https nginx configuration.'
egrep 'server_name\s*test.com' /etc/nginx/sites-available/test.com ||\
	fail "Expected to see a server name of test.com, instead found '$(grep server_name)'"

[[ -f /srv/test.com/cods-config ]] || fail 'Expected to find /srv/test.com/cods-config file'
[[ -d /srv/test.com/repo.git ]] || fail 'Expected to find a repository for test.com'
[[ -x /srv/test.com/repo.git/hooks/post-receive ]] ||\
	fail 'Expected to find an executable post-receive hook'

test

echo ' done.'

# echo '[DEBUG] Exiting early, leaving site intact'
# exit 0

echo -n '  Cleaning up...'
remove_site --domain test.com --force
echo ' ok.'

echo '[TESTING] Finshed.'
