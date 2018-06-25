##############################################################################
# Site management script
#
# This script contains functions for site management, and will run the
# appropriate function based on the arguments passed to it. Most of the
# functionality here is for setting up nginx to host sites either statically, or
# as a reverse proxy to an application server, as well as enabling https for
# sites.
##############################################################################

list_sites() {
	ssh $user@$ip 'ls -1 /etc/nginx/sites-available' | grep -v '^default$'
}

create_site() {
	usage() {
		cat <<-.
		Setup up the server to host a new site. The domain name and one of
		{--static --java --node} must be provided.

		-d|--domain <domain> -- (required) domain name of the site to create
		--static             -- setup a static site
		--java               -- setup a java site
		--node               -- setup a node site
		-p|--port            -- port number that the application will run on
		                        (required for --node and --java)
		--spring-boot        -- (optional) designate that this is a spring boot site
		--enable-ssl         -- (optional) enable ssl after setting up the site
		                        (see the enablessl subcommand)

		Examples:
		    $(basename "$0") site create -d example.com
		    $(basename "$0") site create --domain=example.com --node --port=3000
		    $(basename "$0") site create --domain=example.com --java -p 8080 --enable-ssl --spring-boot
		    $(basename "$0") site create --domain example.com --static
		.
	}
	if [[ $# -eq 0 || $1 == *help || $1 = -h ]] ; then
		usage ; die
	fi
	local domain enablessl force springboot sitetype port arg
	while [[ $# -gt 0 ]] ; do
	    arg=$1 ; shift
	    case $arg in
			-d|--domain) domain=$1 ; shift;;
			--domain=*) domain=${arg#*=};;
			--enable-ssl) enablessl=yes;;
			-f|--force) force=yes;;
			--spring-boot) springboot=yes;;
			-s|--static) [[ -n $sitetype ]] && die 'type already specified' || sitetype=static ;;
			-j|--java) [[ -n $sitetype ]] && die 'type already specified' || sitetype=java ;;
			-n|--node) [[ -n $sitetype ]] && die 'type already specified' || sitetype=node ;;
			-p|--port) port=$1 ; shift;;
			--port=*) port=${arg#*=};;
	        *) echo "Unknown argument: $arg" ; exit 1;;
	    esac
	done

	[[ -z $domain ]] && die 'The domain name is required'
	[[ -z $sitetype ]] && die 'Please specify a site type'
	if [[ $sitetype == java || $sitetype == node ]] && [[ -z $port ]] ; then
		die 'Please specify the port number'
	fi

	echo "Making sure $domain isn't already setup..."
	if list_sites | grep "^$domain$" > /dev/null ; then
		echo 'It looks like that site is already setup. Doing nothing.'
		echo 'If you wish to re-create the site, first remove the site, then'
		echo 'create it.'
		die
	else echo 'ok'
	fi
	if [[ $sitetype == java || $sitetype == node ]] ; then
		if [[ $port -gt 65535 || $port -lt 1024 ]] ; then
			die "Invalid port number: ${port}, must be in the range (1024 - 65535)"
		fi
		echo "Checking to make sure port $port is free..."
		existing_port="$(show_ports 2>/dev/null | grep $port)"
		if [[ -n $existing_port ]] ; then
			die "Port $port already in use by $(cut -d\  -f2 <<< $existing_port)"
		else echo ok
		fi
	fi
	echo "Checking DNS records for ${domain}..."
	if [[ "$(dig +short ${domain} | tail -n 1)" != $ip && -z $force ]]; then
		echo 'It looks like the dns records for that domain are not setup to'
		echo 'point to your server.'
		confirm "Are you sure you want to setup ${domain}?" || die 'Aborting...'
	else echo 'ok'
	fi

	if [[ $sitetype == static ]] ; then
		site_create_snippet="$SNIPPETS/create-static-site.sh"
		template=post-receive-static.sh
	else
		site_create_snippet="$SNIPPETS/create-reverse-proxy-site.sh"
		if [[ $sitetype == java ]] ; then
			execstart="/usr/bin/java -jar app.jar --server.port=${port}"
			template=post-receive.sh
		else
			execstart="/usr/bin/npm start"
			template=post-receive-node.sh
		fi
	fi

	echo "Setting up ${domain}..."

	ssh -t $user@$ip "
	set -e
	domain=${domain}
	port=${port}
	execstart='${execstart}'
	template=${template}
	$(< "$site_create_snippet")
	$(< "$SNIPPETS/enable-git-deployment.sh")
	"

	if [[ $springboot == yes ]] ; then
		ssh $user@$ip "domain=${domain} $(< $SNIPPETS/springboot-extra-config.sh)"
	fi

	[[ $? -eq 0 ]] && echo "${domain} created!"

	if [[ $ssl == yes ]] ; then
		echo "Enabling SSL for $domain..."
		enable_ssl --domain $domain
	fi
}

enable_ssl() {
	local domain
	while [[ $# -gt 0 ]] ; do
	    arg=$1 ; shift
	    case $arg in
	        -d|--domain) domain=$1 ; shift;;
	        --domain=*) domain=${arg#*=};;
	        *) echo "Unknown argument: $arg" ; exit 1;;
	    esac
	done
	if [[ -z $domain ]] ; then
		cat <<-.
		Enable https for a site. Before running this command, you should make
		sure that the DNS records for your domain are configured to point to
		your server, otherwise this command *will* fail.

		-d|--domain <domain> -- domain name of the site to enable https for

		Example:
		    $(basename "$0") site enablessl -d example.com
		.
		die
	fi

	echo "Finding port number for ${domain}..."
	port="$(show_ports | grep ${domain} | egrep -o '\d{4,5}')"
	echo "Found port no: ${port}"

	ssh -t $user@$ip "
	set -e
	domain=${domain}
	email=${email}
	port=${port}
	$(< "$SNIPPETS/enable-ssl.sh")
	"
	[[ $? -eq 0 ]] && echo "https enabled for ${domain}!"
}

remove_site() {
	local domain force
	while [[ $# -gt 0 ]] ; do
	    arg=$1 ; shift
	    case $arg in
	        -d|--domain) domain=$1 ; shift;;
	        --domain=*) domain=${arg#*=};;
			-f|--force) force=yes;;
	        *) echo "Unknown argument: $arg" ; exit 1;;
	    esac
	done
	if [[ -z $domain ]] ; then
		cat <<-.
		Remove a site from the server

		-d|--domain <domain> -- name of the site to remove

		Example:
		    $(basename "$0") site remove -d example.com
		.
		die
	fi

	list_sites | grep "^$domain$" >/dev/null || die "It looks like $domain does not exist. Aborting..."
	# confirm deletion
	if [[ -z $force ]] ; then
		confirm "Are you sure you want to remove ${domain}?" || die 'domain not removed.'
	fi

	ssh -t $user@$ip "
	# clean up application server configuration if its a reverse-proxy site
	if grep proxy_pass /etc/nginx/sites-available/${domain} >/dev/null ; then
		sudo systemctl stop ${domain}
		sudo systemctl disable ${domain}.service
		sudo rm -f /etc/systemd/system/${domain}.service
		sudo rm -f /etc/sudoers.d/${domain}
		sudo systemctl daemon-reload
		sudo systemctl reset-failed
	fi

	sudo rm -f /etc/nginx/sites-available/${domain}
	sudo rm -f /etc/nginx/sites-enabled/${domain}
	sudo rm -rf /srv/${domain}

	# remove all users from the group
	for user in \$(ls /home) ; do
		sudo gpasswd -d \$user $domain >/dev/null
	done
	sudo gpasswd -d www-data $domain >/dev/null
	sudo userdel ${domain}
	"

	[[ $? -eq 0 ]] && echo 'site removed!'
}

build_site() {
	local domain
	while [[ $# -gt 0 ]] ; do
	    arg=$1 ; shift
	    case $arg in
	        -d|--domain) domain=$1 ; shift;;
	        --domain=*) domain=${arg#*=};;
	        *) echo "Unknown argument: $arg" ; exit 1;;
	    esac
	done
	if [[ -z $domain ]] ; then
		cat <<-.
		Trigger a build and deploy for a site

		-d|--domain <domain> -- name of the site to build and deploy

		Examples:
		    $(basename "$0") site build -d example.com
		    $(basename "$0") site build --domain=example.com
		.
		die
	fi

	# ensure site exists
	list_sites | grep "^$domain$" >/dev/null || die "It looks like $domain does not exist. Aborting..."

	echo "Running post-receive hook for $domain..."

	# The post-receive hook will ensure that the branch being pushed is the
	# master branch before deploying. Normally this is the behaviour we want,
	# but here we aren't actually pushing, we just want to do the deployment, so
	# we'll need to "fake" the fact that we're pushing the master branch. We'll
	# do so with the echo command below, as git hooks normally recieve the name
	# of the branch being pushed via stdin
	ssh -t $user@$ip "
	cd /srv/${domain}/repo.git
	echo '_ _ master' | hooks/post-receive
	"
}

show_logs() {
	local domain follow
	while [[ $# -gt 0 ]] ; do
	    arg=$1 ; shift
	    case $arg in
	        -d|--domain) domain=$1 ; shift;;
	        --domain=*) domain=${arg#*=};;
			-f|--follow) follow=yes;;
	        *) echo "Unknown argument: $arg" ; exit 1;;
	    esac
	done
	if [[ -z $domain ]] ; then
		cat <<-.
		View server logs for a given site

		-d|--domain <domain> -- Name of the domain to check logs for
		-f|--follow          -- Watch the log file in real-time (press C-c to quit)
		.
		die
	fi
	list_sites | grep "^$domain$" >/dev/null || die "It looks like $domain does not exist. Aborting..."
	if [[ $follow == yes ]] ; then
		ssh $user@$ip sudo journalctl -o short-iso -f -u ${domain}
	else
		ssh $user@$ip sudo journalctl --no-pager -o short-iso -u ${domain}
	fi
}

show_info() {
	local domain
	while [[ $# -gt 0 ]] ; do
	    arg=$1 ; shift
	    case $arg in
	        -d|--domain) domain=$1 ; shift;;
	        --domain=*) domain=${arg#*=};;
	        *) echo "Unknown argument: $arg" ; exit 1;;
	    esac
	done
	if [[ -z $domain ]] ; then
		cat <<-.
		Show information about a site that is setup on the server

		-d|--domain <domain> -- name of the site to show information about

		Example:
		    $(basename "$0") site info -d example.com
		.
		die
	fi

	# ensure site exists
	list_sites | grep "^$domain$" >/dev/null || die "It looks like $domain does not exist. Aborting..."

	cat <<-.
		Site: $domain

		public directory:      /srv/$domain/public
		nginx config file:     /etc/nginx/sites-available/$domain
		deployment git remote: $user@$ip:/srv/$domain/repo.git

		To add the deployment remote for this domain, run:

		    git remote add production $user@$ip:/srv/$domain/repo.git

	.
}

show_help() {
	cat <<-help
	site -- command for managing sites setup on your server
	usage

	    $(basename "$0") site <command> [options]

	where <command> is one of the following:

	    list -- list the sites setup on your server

	    create    -d <domain> {--static|--java|--node} [--enable-ssl] [--spring-boot] [-p <port>]
	    remove    -d <domain> [--force]
	    build     -d <domain>
	    enablessl -d <domain>
	    info      -d <domain>
	    logs      -d <domain> [-f]

	help
}

command=$1
shift

case $command in
	list|ls)   list_sites;;
	create)    create_site "$@";;
	remove|rm) remove_site "$@";;
	build)	   build_site "$@";;
	enablessl) enable_ssl "$@";;
	info)      show_info "$@";;
	logs)      show_logs "$@";;
	deploy)	   deploy_site "$@";;
	*)         show_help;;
esac
