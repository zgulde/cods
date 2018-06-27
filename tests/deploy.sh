usage() {
	echo 'Please provide a domain name and site type to use for testing deployment. E.g.'
	echo
	echo '    myserver _test deploy java testing.example.com'
	echo '    myserver _test deploy static testing.example.com'
	echo
	echo 'Where site type is one of {java,static,node}'
	echo
}

test_type=$1 ; shift
DOMAIN=$1 ; shift

if [[ -z $DOMAIN ]] || [[ -z $test_type ]] ; then
	usage ; exit 1
fi

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
		# fancy progress bar
		for i in {1..40} ; do
			echo -ne "\r[test] $((i / 2))/20 [$(repeat = $i)$(repeat ' ' $((40 - i)))]"
			sleep 0.5
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
	node)
		heading '[TESTING] Creating and Deploying Node site...'

		GIT="git -C $BASE_DIR/tests/sample-sites/node"

		echo '[test] Creating site...'
		create_site --domain $DOMAIN --force --node --port 54321

		$GIT init
		$GIT add .
		$GIT commit -m first
		$GIT remote add origin $user@$ip:/srv/$DOMAIN/repo.git
		echo '[test] Pushing to deploy...'
		$GIT push origin master

		echo '[test] We will wait 5 seconds for the app to startup...'
		# fancy progress bar
		for i in {1..10} ; do
			echo -ne "\r[test] $((i / 2))/20 [$(repeat = $i)$(repeat ' ' $((10 - i)))]"
			sleep 0.5
		done
		echo

		expected='Node Site is Working!'
		response="$(curl -Ss http://$DOMAIN)"

		if [[ $expected != $response ]] ; then
			fail 'Node Site Deployement'
			cat <<-.
			  expected to find  "$expected"
			  but instead found "$response"

			  as a response from $DOMAIN
			.
		else
			echo "[test] Found expected response from node site: $DOMAIN"
		fi

		echo '[test] Removing site...'
		remove_site --domain $DOMAIN --force

		rm -rf $BASE_DIR/tests/sample-sites/node/.git
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
	*) usage ; exit 1;;
esac
