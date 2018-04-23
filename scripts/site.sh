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
			*) echo "Unknown argument: $arg" ; exit 1;;
		esac
	done
	if [[ -z $domain ]] ; then
		cat <<-.
		Setup up the server to host a new site. Optionally also enable ssl or
		setup the site as a spring boot site (this just enables some common
		configuration).
		You should only enable ssl if you know your DNS records are properly
		configured, otherwise you can do this with the separate 'enablessl'
		site subcommand.

		-d|--domain <domain> -- domain name of the site to create
		--enable-ssl         -- (optional) enable ssl after setting up the site
		--spring-boot        -- (optional) designate that this is a spring boot site
		--static             -- (optional) setup a static site

		Examples:
		    $(basename "$0") site create -d example.com
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
	else
		site_create_snippet="$SNIPPETS/create-java-site.sh"
	fi

	echo "Setting up ${domain}..."
	ssh -t $user@$ip "
	set -e
	domain=${domain}
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

deploy_site() {
	while [[ $# -gt 0 ]] ; do
	    arg=$1 ; shift
	    case $arg in
	        -f|--filepath) war_filepath="$1" ; shift;;
	        --filepath=*) war_filepath="${arg#*=}" ; war_filepath="${war_filepath/#\~/$HOME}";;
			-d|--domain) domain=$1 ; shift;;
			--domain=*) domain=${arg#*=};;
	        *) echo "Unknown argument: $arg" ; exit 1;;
	    esac
	done
	if [[ -z $domain ]] || [[ -z $war_filepath ]] ; then
		cat <<-.
		Deploy a pre-built war file.

		You should probably only do this if you really know what youre doing,
		for most use cases, git deployment is recommended. See also the 'build'
		subcommand.

		-d|--domain <domain>     -- name of the site to deploy
		-f|--filepath <filepath> -- path to the war file

		Example:
		    $(basename "$0") site deploy -d example.com -f ~/example-project.war
		.
		die
	fi

	# ensure file exists and is a war (or at least has the extension)
	if [[ ! -f "$war_filepath" ]]; then
		echo 'It looks like that file does not exist!'
		exit 1
	fi
	if [[ "$war_filepath" != *.war ]] ; then
		echo 'It looks like that file is not a valid war file (it does not have the)' >&2
		die '".war" file extension. Aborting...'
	fi

	# ensure site exists
	list_sites | grep "^$domain$" >/dev/null || die "It looks like $domain does not exist. Aborting..."

	scp "$war_filepath" $user@$ip:/opt/tomcat/${domain}/ROOT.war
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

	    create        -d <domain> [--static] [--enable-ssl] [--spring-boot]
	    remove        -d <domain>
	    build         -d <domain>
	    enablessl     -d <domain>
	    info          -d <domain>
	    deploy        -d <domain> -f <warfile>

	help
}

command=$1
shift

case $command in
	list|ls)       list_sites;;
	create)        create_site "$@";;
	remove|rm)     remove_site "$@";;
	build)	       build_site "$@";;
	enablessl)     enable_ssl "$@";;
	info)          show_info "$@";;
	deploy)	       deploy_site "$@";;
	*)             show_help;;
esac
