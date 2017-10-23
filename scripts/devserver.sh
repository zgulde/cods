#!/bin/bash

if ! which nginx >/dev/null; then
    echo 'Please install nginx first.' 1>&2
    exit 1
fi

nginx_config_file=/tmp/devserver-nginx.conf

cleanup() {
    rm $nginx_config_file
    echo 'Goodbye!'
    exit $1
}

domain=$1
webroot=$2

if [[ -z $domain ]]; then
    cat 1>&2 <<'help'
Usage

    ./server devserver <domain> [webroot]

Description

    Start a development webserver listening for a domain, optionally with a
    custom webroot. The server will proxy all requests off to localhost:8080,
    except for requests to `/uploads`, which will be served from the webroot.
    The webroot will default to ~/tmp/uploads if none is passed when the server
    is started. Note that you will need an entry in your /etc/hosts file for
    the given domain.

Examples

- Start the server for mydomain.dev

    ./server devserver mydomain.dev

- Start the server for codeup.dev with a custom webroot

    ./server devserver codeup.dev ~/Downloads/tmp

help
    exit 1
fi

if [[ -z $webroot ]]; then
    webroot=/Users/$USER/tmp
    mkdir -p $webroot/uploads
fi

if [[ -f $nginx_config_file ]]; then
    echo "It looks like the server is already running. ($nginx_config_file exists)"
    echo "To restart, remove $nginx_config_file"
    exit 1
fi

perl -pe "s/DOMAIN/${domain}/g; s!WEBROOT!${webroot}!g"\
    $TEMPLATES/nginx-dev.conf\
    > $nginx_config_file

echo "Starting development webserver!"
sudo echo 'sudo test' >/dev/null # get sudo password here so we aren't prompted later
echo
echo "Domain:            ${domain}"
echo "Webroot:           ${webroot}"
echo "Uploads Directory: ${webroot}/uploads"
echo
echo 'Server running, press Ctrl-C to exit.'
echo

trap cleanup INT

sudo nginx -c $nginx_config_file -g 'daemon off;'
