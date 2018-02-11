heading "Testing site commands..."

logfile="$BASE_DIR/testing.log"

eval "$(< $SCRIPTS/site.sh)" >/dev/null

( create_site > /dev/null ) && fail 'It should exit with a non-zero status when invoked with no arguments'

echo '[TESTING] Site Creation (nginx + tomcat + git deployment)'
echo 'Creating test site...'
create_site --domain test.com --spring-boot --force >>$logfile 2>&1

ssh $user@$ip >/dev/null <<'test'
fail() { echo "[FAIL] $@" >&2 ; exit 1; }

[[ -d /var/www/test.com/uploads ]] ||\
	fail 'Expected an uploads directory to be created'
stat=$(stat --format='%G:%U' /var/www/test.com/uploads)
[[ $stat == 'tomcat:tomcat' ]] ||\
	fail "Expected uploads directory to be owned by 'tomcat:tomcat', found '$stat'"
[[ -f /etc/nginx/sites-available/test.com ]] ||\
	fail 'Expected /etc/nginx/sites-available/test.com to exist'
[[ -L /etc/nginx/sites-enabled/test.com ]] ||\
	fail 'Expected /etc/nginx/sites-enabled/test.com to be a symlink'
[[ $(readlink /etc/nginx/sites-enabled/test.com) == /etc/nginx/sites-available/test.com ]] ||\
	fail 'Expected a link to the config file in sites-enabled from sites-available'
# make sure we used the right template
grep proxy_pass /etc/nginx/sites-available/test.com >/dev/null ||\
	fail 'Expected to find "proxy_pass" in nginx config'

sudo grep test.com /opt/tomcat/conf/server.xml >/dev/null ||\
	fail 'Expected to find test.com in tomcat server config'
[[ -d /opt/tomcat/test.com ]] ||\
	fail 'Expected to find a test.com directory within the tomcat installation'
stat=$(stat --format='%G:%U' /opt/tomcat/test.com)
[[ $stat == 'tomcat:tomcat' ]] ||\
	fail "Expected test.com tomcat directory to be owned by 'tomcat:tomcat', found '$stat'"

[[ -d /srv/test.com ]] || fail 'Expected to find /srv/test.com directory'
[[ -f /srv/test.com/config ]] || fail 'Expected to find a config file for test.com'
(
	grep '^source=application.properties$' /srv/test.com/config >/dev/null &&\
	grep '^destination=src/main/resources/application.properties' /srv/test.com/config >/dev/null
) || fail 'Expected to find config file pre-modified for a spring-boot app'

[[ -d /srv/test.com/repo.git ]] || fail 'Expected to find a repository for test.com'
[[ -x /srv/test.com/repo.git/hooks/post-receive ]] ||\
	fail 'Expected to find an executable post-receive hook'

test
[[ $? -eq 0 ]] || exit 1

echo 'Cleaning up...'
remove_site --domain test.com --force >>$logfile 2>&1
echo '[PASS]'
