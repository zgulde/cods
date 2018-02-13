heading "Testing site commands..."

logfile="$BASE_DIR/testing.log"

eval "$(< $SCRIPTS/site.sh)" >/dev/null

( create_site > /dev/null ) && fail 'It should exit with a non-zero status when invoked with no arguments'

echo '[TESTING] Site Creation (nginx + tomcat + git deployment)'
echo -n '  Creating test site...'
create_site --domain test.com --spring-boot --force >>$logfile 2>&1
echo ' ok.'

echo -n '  Running tests...'
ssh -T $user@$ip >/dev/null <<'test'
fail() { echo -e "  \033[01;31m[FAIL]\033[0m $@" >&2 ; }

[[ -d /srv/test.com/ ]] ||\
	fail 'Expected to find a directory created in /srv'
[[ -d /srv/test.com/public ]] ||\
	fail 'Expected to find a public directory for the site'
stat=$(stat --format='%G' /srv/test.com/public)
[[ $stat == 'tomcat' ]] ||\
	fail "Expected the public directory to be owned by 'tomcat' group, found '$stat'"
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

sudo grep test.com /opt/tomcat/conf/server.xml >/dev/null ||\
	fail 'Expected to find test.com in tomcat server config'
[[ -d /opt/tomcat/test.com ]] ||\
	fail 'Expected to find a test.com directory within the tomcat installation'
stat=$(stat --format='%G:%U' /opt/tomcat/test.com)
[[ $stat == 'tomcat:tomcat' ]] ||\
	fail "Expected test.com tomcat directory to be owned by 'tomcat:tomcat', found '$stat'"

[[ -f /srv/test.com/config ]] || fail 'Expected to find a config file for test.com'
(
	grep '^source=application.properties$' /srv/test.com/config &&\
	grep '^destination=src/main/resources/application.properties$' /srv/test.com/config
) >/dev/null || fail 'Expected to find config file pre-modified for a spring-boot app'

[[ -d /srv/test.com/repo.git ]] || fail 'Expected to find a repository for test.com'
[[ -x /srv/test.com/repo.git/hooks/post-receive ]] ||\
	fail 'Expected to find an executable post-receive hook'

test
echo ' done.'

echo -n '  Cleaning up...'
remove_site --domain test.com --force >>$logfile 2>&1
echo ' ok.'

echo '[TESTING] Static Site Creation'
echo -n '  Creating site...'
create_site --domain test.com --static --force >>$logfile 2>&1
echo ' ok.'
echo -n '  Running tests...'

ssh -T $user@$ip >/dev/null <<'test'
fail() { echo -e "  \033[01;31m[FAIL]\033[0m $@" >&2 ; }

[[ -d /srv/test.com ]] ||\
	fail 'Expected a directory in /srv to be created'
[[ -d /srv/test.com/public ]] ||\
	fail 'Expected a public directory to be created'
stat=$(stat --format='%G' /srv/test.com/public)
[[ $stat == 'tomcat' ]] ||\
	fail "Expected public directory to be owned by group tomcat, instead found $stat"
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
	fail 'Expected not to find ssl nginx configuration.'
egrep 'server_name\s*test.com' /etc/nginx/sites-available/test.com ||\
	fail "Expected to see a server name of test.com, instead found '$(grep server_name)'"

[[ -f /srv/test.com/config ]] || fail 'Expected to find /srv/test.com/config file'
[[ -d /srv/test.com/repo.git ]] || fail 'Expected to find a repository for test.com'
[[ -x /srv/test.com/repo.git/hooks/post-receive ]] ||\
	fail 'Expected to find an executable post-receive hook'

test

echo ' done.'
echo -n '  Cleaning up...'
remove_site --domain test.com --force >>$logfile 2>&1
echo ' ok.'

echo '[TESTING] Finshed.'
