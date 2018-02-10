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

enable_git_deploment() {
	domain=$1
	[[ -z $domain ]] && die 'Error in enable_git_deployment: $domain not specified'
	echo "Setting up git deployment..."

	ssh -t $user@$ip "
        sudo chmod g+srwx /srv
	mkdir /srv/${domain}
	cat > /srv/${domain}/config <<'.'
$(cat $TEMPLATES/config)
.
	git init --bare --shared=group /srv/${domain}/repo.git
	cat > /srv/${domain}/repo.git/hooks/post-receive <<'.'
$(sed -e s/{{site}}/$domain/g $TEMPLATES/post-receive.sh)
.
	chmod +x /srv/${domain}/repo.git/hooks/post-receive
	"
	echo "git deployment configured!"
	echo "Here is your deployment remote:"
	echo
	echo "	$user@$ip:/srv/${domain}/repo.git"
	echo
	echo "You can run something like:"
	echo
	echo "	git remote add production $user@$ip:/srv/${domain}/repo.git"
	echo
	echo "To add the remote."
}

create_site() {
	while [[ $# -gt 0 ]] ; do
	    arg=$1 ; shift
	    case $arg in
	        -d|--domain) domain=$1 ; shift;;
	        --domain=*) domain=${arg#*=};;
			--enable-ssl) ssl=yes;;
	        *) echo "Unknown argument: $arg" ; exit 1;;
	    esac
	done
	if [[ -z $domain ]] ; then
		cat <<-.
		Setup up the server to host a new site. Optionally also enable ssl.
		You should only enable ssl if you know your DNS records are properly
		configured, otherwise you can do this with the separate 'enablessl'
		site subcommand.

		-d|--domain <domain> -- domain name of the site to create
		--enable-ssl         -- (optional) enable ssl for the setup site

		Example:
		    $(basename $0) site create -d example.com
		    $(basename $0) site create --domain=example.com --enable-ssl
		.
		die
	fi

	if list_sites | grep "^$domain$" > /dev/null ; then
		echo 'It looks like that site is already setup. Doing nothing.'
		echo 'If you wish to re-create the site, first remove the site, then'
		echo 're-create it.'
		exit 1
	fi

	# verify dns records
	if [[ "$(dig +short ${domain} | tail -n 1)" != $ip ]]; then
		echo 'It looks like the dns records for that domain are not setup to'
		echo 'point to your server.'
		confirm "Are you sure you want to setup ${domain}?" || die 'Aborting...'
	fi

	echo "Setting up ${domain}..."

	ssh -t $user@$ip "
	set -e
	# tomcat config
	echo 'Configuring tomcat...'
	sudo perl -i -pe 's!^.*--## Virtual Hosts ##--.*\$!$&\n\
	<Host name=\"${domain}\" appBase=\"${domain}\" unpackWARs=\"true\" autoDeploy=\"true\" />!' \
		/opt/tomcat/conf/server.xml
	sudo mkdir -p /opt/tomcat/${domain}
	sudo chown -R tomcat:tomcat /opt/tomcat/${domain}
	sudo chmod -R g+w /opt/tomcat/${domain}
	echo 'Restarting tomcat...'
	sudo systemctl restart tomcat

	sudo mkdir -p /var/www/${domain}/uploads
	sudo chmod g+rw /var/www/${domain}/uploads
	sudo chown -R tomcat:tomcat /var/www/${domain}/uploads

	# nginx config
	echo 'Configuring nginx...'
	echo '$(sed -e s/{{domain}}/${domain}/g -e s/{{user}}/${user}/g $TEMPLATES/site.nginx.conf)' |\
		sudo tee /etc/nginx/sites-available/${domain} >/dev/null
	sudo ln -s /etc/nginx/sites-available/${domain} /etc/nginx/sites-enabled/${domain}
	echo 'Restarting nginx...'
	sudo systemctl restart nginx
	"
	[[ $? -eq 0 ]] && echo "${domain} created!"

	enable_git_deploment $domain
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
		    $(basename $0) site enablessl -d example.com
		.
		die
	fi

	echo 'Requesting SSL certificate... (this might take a second)'
	ssh -t $user@$ip "
	set -e
	mkdir -p /srv/${domain}
	sudo letsencrypt certonly\
		--authenticator webroot\
		--webroot-path=/var/www/${domain}\
		--domain ${domain}\
		--agree-tos\
		--email $email\
		--renew-by-default >> /srv/letsencrypt.log

	echo 'Setting up nginx to serve ${domain} over https...'
	echo '$(sed -e s/{{domain}}/${domain}/g -e s/{{user}}/${user}/g $TEMPLATES/ssl-site.nginx.conf)' |\
		sudo tee /etc/nginx/sites-available/${domain} >/dev/null
	sudo systemctl restart nginx
	"

	[[ $? -eq 0 ]] && echo "https enabled for ${domain}!"
}

remove_site() {
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
		Remove a site from the server

		-d|--domain <domain> -- name of the site to remove

		Example:
		    $(basename $0) site remove -d example.com
		.
		die
	fi

	list_sites | grep "^$domain$" >/dev/null || die "It looks like $site does not exist. Aborting..."
	# confirm deletion
	confirm "Are you sure you want to remove ${site}?" || die 'Site not removed.'

	ssh -t $user@$ip "
	sudo sed -i -e '/${site}/d' /opt/tomcat/conf/server.xml

	sudo rm -f /etc/nginx/sites-available/${site}
	sudo rm -f /etc/nginx/sites-enabled/${site}
	sudo rm -rf /opt/tomcat/${site}
	sudo rm -rf /opt/tomcat/conf/Catalina/${site}
	sudo rm -rf /var/www/${site}
	sudo rm -rf /srv/${site}
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
		    $(basename $0) site build -d example.com
		    $(basename $0) site build --domain=example.com
		.
		die
	fi

	# ensure site exists
	list_sites | grep "^$site$" >/dev/null || die "It looks like $site does not exist. Aborting..."

	echo "Running post-receive hook for $site"

	ssh -t $user@$ip "
	cd /srv/$site/repo.git
	hooks/post-receive
	"
}

deploy_site() {
	while [[ $# -gt 0 ]] ; do
	    arg=$1 ; shift
	    case $arg in
	        -f|--filepath) war_filepath=$1 ; shift;;
	        --filepath=*) war_filepath=${arg#*=} ; war_filepath="${war_filepath/#\~/$HOME}";;
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
		    $(basename $0) site deploy -d example.com -f ~/example-project.war
		.
		die
	fi

	# ensure file exists and is a war (or at least has the extension)
	if [[ ! -f $war_filepath ]]; then
		echo 'It looks like that file does not exist!'
		exit 1
	fi
	if [[ "$war_filepath" != *.war ]] ; then
		echo 'It looks like that file is not a valid war file (it does not have the)' >&2
		die '".war" file extension. Aborting...'
	fi

	# ensure site exists
	list_sites | grep "^$domain$" >/dev/null || die "It looks like $site does not exist. Aborting..."

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
		    $(basename $0) site info -d example.com
		.
		die
	fi

	# ensure site exists
	list_sites | grep "^$domain$" >/dev/null || die "It looks like $site does not exist. Aborting..."

	cat <<-.
		Site: $domain

		uploads directory:     /var/www/$site/uploads
		nginx config file:     /etc/nginx/sites-available/$site
		deployment git remote: $user@$ip:/srv/$site/repo.git

		To add the deployment remote for this site, run:

		    git remote add production $user@$ip:/srv/$site/repo.git

	.
}

show_help() {
	cat <<-help
	site -- command for managing sites setup on your server
	usage

	    $(basename $0) site <command> [options]

	where <command> is one of the following:

	    list -- list the sites setup on your server

	    create    -d <domain>
	    remove    -d <domain>
	    build     -d <domain>
	    enablessl -d <domain>
	    info      -d <domain>
	    deploy    -d <domain> -f <warfile>

	help
}

command=$1
shift

case $command in
	list|ls)   list_sites;;
	create)	   create_site $@;;
	remove|rm) remove_site $@;;
	build)	   build_site $@;;
	enablessl) enable_ssl $@;;
	info)      show_info $@;;
	deploy)	   deploy_site $@;;
	*)         show_help;;
esac
