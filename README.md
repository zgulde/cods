# Setup Scripts

For setup and management of a remote server and individual sites with tomcat,
nginx, and mysql.

## Who this is for

Primarily, these scripts are intended to be used by [Codeup](http://codeup.com)
students going through the Java program. However, you might find this repo
useful if you have a Java web application you want to deploy quickly with
tomcat, or if you want to host several Java projects on the same server.

This project is probably **not** for you if:

- You need to deploy anything that is not a `war`
- You want to use a database that is not MySQL
- You want to use a webserver other than tomcat

## Prerequisites

1. A java web application packaged as a war that can be served by Tomcat.
1. A server with a fresh ubuntu 16.04 install
1. Your ssh key on that server with access to the root account
1. For any domain (or subdomain) you want to host on your server, you will need
   to have the DNS records already configured to point to your server's IP.

## Quick Start

Deploy a blog application and create a database for it:

```bash
# 1. clone this repo
git clone https://github.com/zgulde/tomcat-setup.git ~/my-awesome-server
cd ~/my-server

# 2. provision the server
./setup

# 3. create a database and user for the application
./db create blog_db blog_user
./db migrate blog_db ~/IdeaProjects/myblog/migration.sql

# 4. setup your server to listen for requests for your domain
./site create myblog.com

# 5. deploy the war
./site deploy myblog.com ~/IdeaProjects/myblog/target/myblog-v0.0.1-SNAPSHOT.war
```

## HTTPS

The `site` command has a sub command that will obtain a certificate from
[letsencrypt](https://letsencrypt.org/) and enable https on a per-site basis.

**Before using this command make sure you agree to the [Lets Encrypt Subscriber
Agreement](https://letsencrypt.org/documents/LE-SA-v1.1.1-August-1-2016.pdf).**

Simply run

```bash
./site enablessl myawesomesite.com
```

## Commands

Except for `setup`, each command has individual subcommands that must be run,
documented in the bullet points below. Invoking just the command by itself will
show a list of available subcommands and the arguments they take. All subcommand
arguments are optional, they can either be passed on the command line, or you
will be prompted for them interactively after invoking the command.

`./setup` 

Setup your server for the first time. Before running this, make sure you
have a server created and have it's ip address. Also be prepared to choose a
administrator password for both your server and your database.

`./server`

- `login`: log in to the server
- `upload`: upload a file to the server
- `info`: view some general information about your server
- `restart`: restart a specific service. Shortcut for logging in and running
  `sudo systemctl restart ...`
- `reboot`: reboot the server

`./site`

- `list`: view the sites that are currently setup on the server
- `create`: create a new site
- `remove`: remove a site. Will remove the nginx config for the site, as well as
  any previously deployed `war`s
- `enablessl`: enable https for a site
- `deploy`: deploy a `war` file for an individual site

`./db`

- `login`: login to your mysql database
- `list`: list the databases that exist on your server
- `create`: create a new database and a user with privileges on only that
  database
- `backup`: create a backup of a database
- `migrate`: run a migration script for a specific database
- `remove`: remove a database and user
