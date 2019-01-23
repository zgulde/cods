usage() {
	echo 'Please provide a domain name and site type to use for testing deployment. E.g.'
	echo
	echo '    myserver _test deploy java testing.example.com'
	echo '    myserver _test deploy static testing.example.com'
	echo
	echo 'Where site type is one of {java,static,node,python}'
	echo
}

success() { echo -e "\033[01;32m$@\033[0m" ; }
fail() { echo -e "  \033[01;31m[FAIL]\033[0m $@" ; }

test_type=$1 ; shift
DOMAIN=$1 ; shift

if [[ -z $DOMAIN ]] || [[ -z $test_type ]] ; then
	usage ; exit 1
fi

eval "$(< $SCRIPTS/site.sh)" >/dev/null

# TODO: There's quite a bit of duplication going on with setting up the sample
# git repo, setting up the site, then checking for the expected response. Maybe
# we should clean this up? On the other hand I think it's good for tests to be
# explicit, i.e. these tests all relate to the public-facing api, so maybe it
# should be painful to make changes to them, as we don't want to change the
# public facing api all too much
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
			echo -ne "\r[test] $((i / 2))/5 [$(repeat = $i)$(repeat ' ' $((10 - i)))]"
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
	python)
		heading '[TESTING] Creating and Deploying Python site...'

		GIT="git -C $BASE_DIR/tests/sample-sites/python-flask"

		echo '[test] Creating site...'
		create_site --domain $DOMAIN --force --python --port 54321

		$GIT init
		$GIT add .
		$GIT commit -m first
		$GIT remote add origin $user@$ip:/srv/$DOMAIN/repo.git
		echo '[test] Pushing to deploy...'
		$GIT push origin master

		echo '[test] We will wait 5 seconds for the app to startup...'
		# fancy progress bar
		for i in {1..10} ; do
			echo -ne "\r[test] $((i / 2))/5 [$(repeat = $i)$(repeat ' ' $((10 - i)))]"
			sleep 0.5
		done
		echo

		expected='Python Flask site is working!'
		response="$(curl -Ss http://$DOMAIN)"

		if [[ $expected != $response ]] ; then
			fail 'Python Site Deployement'
			cat <<-.
			  expected to find  "$expected"
			  but instead found "$response"

			  as a response from $DOMAIN
			.
		else
			echo "[test] Found expected response from python site: $DOMAIN"
		fi

		echo '[test] Removing site...'
		remove_site --domain $DOMAIN --force

		rm -rf $BASE_DIR/tests/sample-sites/python-flask/.git
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
			echo "[test] Found expected response from static site deployed at $DOMAIN"
			success '[test] Pass'
		fi

		echo '[test] Removing site...'
		remove_site --domain $DOMAIN --force

		rm -rf $BASE_DIR/tests/sample-sites/static/.git

		heading '[TESTING] Creating and Deploying static site with a install.sh file...'
		GIT="git -C $BASE_DIR/tests/sample-sites/static-with-build"
		echo '[test] Creating site...'
		create_site --domain $DOMAIN --static --force

		$GIT init
		$GIT add .
		$GIT commit -m first
		$GIT remote add origin $user@$ip:/srv/$DOMAIN/repo.git
		echo '[test] Pushing to deploy...'
		$GIT push origin master

		expected='Static Site with a build step is Working!'
		response="$(curl -Ss http://$DOMAIN)"

		if [[ $expected != $response ]] ; then
			fail 'Static Site with install.sh file Deployement'
			cat <<-.
			  expected to find  "$expected"
			  but instead found "$response"

			  as a response from $DOMAIN
			.
		else
			echo "[test] Found expected response from static install.sh deploy at $DOMAIN"
			success '[test] Pass'
		fi

		echo '[test] Removing site...'
		remove_site --domain $DOMAIN --force

		rm -rf $BASE_DIR/tests/sample-sites/static-with-build/.git

		heading '[TESTING] Creating and Deploying static site with a .cods file...'
		GIT="git -C $BASE_DIR/tests/sample-sites/static-with-dot-cods"
		echo '[test] Creating site...'
		create_site --domain $DOMAIN --static --force

		$GIT init
		$GIT add .
		$GIT commit -m first
		$GIT remote add origin $user@$ip:/srv/$DOMAIN/repo.git
		echo '[test] Pushing to deploy...'
		$GIT push origin master

		expected='static with .cods is working'
		response="$(curl -Ss http://$DOMAIN)"

		if [[ $expected != $response ]] ; then
			fail 'Static Site With ".cods" Deployement'
			cat <<-.
			  expected to find  "$expected"
			  but instead found "$response"

			  as a response from $DOMAIN
			.
		else
			echo "[test] Found expected response from static .cods deploy at $DOMAIN"
			success '[test] Pass'
		fi

		echo '[test] Removing site...'
		remove_site --domain $DOMAIN --force

		rm -rf $BASE_DIR/tests/sample-sites/static-with-dot-cods/.git
		;;
	*) usage ; exit 1;;
esac
