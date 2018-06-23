DOMAIN=testing.zach.lol

test_type=$1 ; shift

eval "$(< $SCRIPTS/site.sh)" >/dev/null

case $test_type in
	java)
		heading '[TESTING] Creating and Deploying Java site...'

		GIT="git -C $BASE_DIR/tests/sample-sites/java"

		echo '[test] Creating site...'
		create_site --domain $DOMAIN --force --java --port 12345

		$GIT init
		$GIT add .
		$GIT commit -m first
		$GIT remote add origin $user@$ip:/srv/$DOMAIN/repo.git
		echo '[test] Pushing to deploy...'
		$GIT push origin master

		echo '[test] We have to wait a bit for the java application to start up...'
		echo '[test] 20 seconds is usually more than enough...'
		for n in {1..20} ; do
			sleep 1
			echo -ne "\r[test] $n"
		done
		echo

		expected='Java Site is Working!'
		response="$(curl -Ss http://$DOMAIN)"

		if [[ $expected != $response ]] ; then
			fail 'Java Site Deployement'
			cat <<-.
			  expected to find  "$expected"
			  but instead found "$response"

			  as a response from $DOMAIN
			.
		else
			echo "[test] Found expected response from java site: $DOMAIN"
		fi

		echo '[test] Removing site...'
		remove_site --domain $DOMAIN --force

		rm -rf $BASE_DIR/tests/sample-sites/java/.git
		;;
	static)
		heading '[TESTING] Creating and Deploying static site...'

		GIT="git -C $BASE_DIR/tests/sample-sites/static"
		echo '[test] Creating site...'
		create_site --domain $DOMAIN --static --force

		$GIT init
		$GIT add .
		$GIT commit -m first
		$GIT remote add origin $user@$ip:/srv/$DOMAIN/repo.git
		echo '[test] Pushing to deploy...'
		$GIT push origin master

		expected='Static Site is Working!'
		response="$(curl -Ss http://$DOMAIN)"

		if [[ $expected != $response ]] ; then
			fail 'Static Site Deployement'
			cat <<-.
			  expected to find  "$expected"
			  but instead found "$response"

			  as a response from $DOMAIN
			.
		else
			echo "[test] Found expected response from $DOMAIN"
		fi

		echo '[test] Removing site...'
		remove_site --domain $DOMAIN --force

		rm -rf $BASE_DIR/tests/sample-sites/static/.git
		;;
	*) echo 'static | java';;
esac
