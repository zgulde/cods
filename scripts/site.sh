##############################################################################
# Site management script
#
# This script contains functions for site management, and will run the
# appropriate function based on the arguments passed to it. Most of the
# functionality here is for setting up nginx and tomcat to host sites, as well
# as enabling https for sites.
##############################################################################

list_sites() {
	ssh $user@$ip 'ls -1 /etc/nginx/sites-available' | grep -v '^default$'
}

create_site() {
	while [[ $# -gt 0 ]] ; do
		arg=$1 ; shift
		case $arg in
			-d|--domain) domain=$1 ; shift;;
			--domain=*) domain=${arg#*=};;
			--enable-ssl) ssl=yes;;
			--sb|--spring-boot) springboot=yes;;
			--static) static_site=yes;;
			--force) force_creation=yes;;
			--node=*) node_port=${arg#*=};;
			--node) node_site=yes;;
			-p|--port) port=$1 ; shift;;
			--port=*) port=${arg#*=};;
			*) echo "Unknown argument: $arg" ; exit 1;;
		esac
	done
	if [[ -z $domain ]] ; then
		cat <<-.
		Setup up the server to host a new site. Optionally also enable ssl or
		setup the site as a spring boot site (this just enables some common
		configuration).
		By default a java site served by tomcat is created

		-d|--domain <domain>   -- (required) domain name of the site to create
		--enable-ssl           -- (optional) enable ssl after setting up the site
		                          (see the enablessl subcommand)
		--spring-boot          -- (optional) designate that this is a spring boot site
		--static               -- setup a static site
		--node                 -- setup a node site. The port number that the application
		                          runs on must be provided through --port
		-p|--port              -- port number that the application will run on

		Examples:
		    $(basename "$0") site create -d example.com
		    $(basename "$0") site create --domain=example.com --node --port=3000
		    $(basename "$0") site create --domain=example.com --enable-ssl --spring-boot
		    $(basename "$0") site create --domain example.com --static
		.
		die
	fi

	if list_sites | grep "^$domain$" > /dev/null ; then
		echo 'It looks like that site is already setup. Doing nothing.'
		echo 'If you wish to re-create the site, first remove the site, then'
		echo 'create it.'
		exit 1
	fi

	# verify dns records
	if [[ "$(dig +short ${domain} | tail -n 1)" != $ip && -z $force_creation ]]; then
		echo 'It looks like the dns records for that domain are not setup to'
		echo 'point to your server.'
		confirm "Are you sure you want to setup ${domain}?" || die 'Aborting...'
	fi

	if [[ $static_site == yes ]] ; then
		site_create_snippet="$SNIPPETS/create-static-site.sh"
	elif [[ $node_site == yes ]] ; then
		if [[ -z $port ]] ; then
			echo 'Missing port number (--port)'
			exit 1
		fi
		site_create_snippet="$SNIPPETS/create-node-site.sh"
	else
		site_create_snippet="$SNIPPETS/create-java-site.sh"
	fi

	echo "Setting up ${domain}..."
	ssh -t $user@$ip "
	set -e
	domain=${domain}
	port=${port}
	$(< "$site_create_snippet")
	$(< "$SNIPPETS/enable-git-deployment.sh")
	"

	[[ $? -eq 0 ]] && echo "${domain} created!"

	if [[ $springboot == yes ]] ; then
		ssh $user@$ip "domain=${domain} $(< $SNIPPETS/springboot-extra-config.sh)"
	fi
	if [[ $ssl == yes ]] ; then
		echo "Enabling SSL for $domain..."
		enable_ssl --domain $domain
	fi
}

enable_ssl() {
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

	ssh -t $user@$ip "
	set -e
	domain=${domain}
	email=${email}
	$(< "$SNIPPETS/enable-ssl.sh")
	"
	[[ $? -eq 0 ]] && echo "https enabled for ${domain}!"
}

remove_site() {
	while [[ $# -gt 0 ]] ; do
	    arg=$1 ; shift
	    case $arg in
	        -d|--domain) domain=$1 ; shift;;
	        --domain=*) domain=${arg#*=};;
			--force) force=yes;;
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
	sudo sed -i -e '/${domain}/d' /opt/tomcat/conf/server.xml

	sudo rm -f /etc/nginx/sites-available/${domain}
	sudo rm -f /etc/nginx/sites-enabled/${domain}
	sudo rm -rf /opt/tomcat/${domain}
	sudo rm -rf /opt/tomcat/conf/Catalina/${domain}
	sudo rm -rf /srv/${domain}
	sudo systemctl stop ${domain} 2>/dev/null
	sudo systemctl disable ${domain}.service 2>/dev/null
	sudo rm -f /etc/systemd/system/${domain}.service
	sudo rm -f /etc/sudoers.d/${domain}
	sudo systemctl daemon-reload
	sudo systemctl reset-failed
	"

	[[ $? -eq 0 ]] && echo 'site removed!'
}

build_site() {
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

	ssh -t $user@$ip "
	cd /srv/${domain}/repo.git
	hooks/post-receive
	"
}

show_logs() {
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
	if [[ $follow == yes ]] ; then
		ssh $user@$ip sudo journalctl -o short-iso -f -u ${domain}
	else
		ssh $user@$ip sudo journalctl --no-pager -o short-iso -u ${domain}
	fi
}

show_info() {
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
