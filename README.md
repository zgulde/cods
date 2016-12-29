# Setup Scripts

For setup and management of a remote server and virtual hosting with tomcat,
nginx, and mysql.

* [Who this is for](#who-this-is-for)
* [Prerequisites](#prerequisites)
* [Quick Start](#quick-start)
* [Usage](#usage)
* [HTTPS](#https)
* [Commands](#commands)
* [Sharing your server with teammates](#sharing-your-server-with-teammates)

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
cd ~/my-awesome-server

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

## Usage

The setup script is intended to setup and secure a server with a fresh install
of Ubuntu 16.04 and only a root account. When the server is first setup, a
`.env` file will be created that contains the name of the account you created
and the server's ip address. All of the other commands for managing the server
will check for this `.env` file to make sure the server is setup before trying
to do anything.

Broadly speaking, most of the commands will ssh into the server and run a command
or a series of commands to achieve the goal of the command. This allows us to
control the server from a local machine, without much need to log in to the
server itself.

All of the scripts should be run from the directory where you initially cloned
this repository. To run the scripts, you will need to prefix them with a `./`.
To cancel the execution of a script, you can press Control + C.

Clone this repo once per server you wish to automate. For example, you might
have the following directory structure

```
~/
`---servers/
    `---personal-server/
    `---my-awesome-sideproject/
    `---capstone-project/
```

Once you have cloned this repo, you will need to setup and provision the server.
Have the ip address of your server handy, and then run the `setup` script.

This setup will allow you to host multiple different domains on each server. For
each site you wish to host, you will need to:

1. Setup the DNS Records for that domain to point to your server
1. Create the site
1. Create a database and user for the application
1. Deploy a `war` that contains the application

When creating a new site, the `site create` command will check to see if the DNS
records for the given domain point to your server. You will be given a warning
if they do not, but you can go ahead and create the site anyway if you are still
configuring DNS, or waiting for the records to propogate. To test your site
under these conditions, you can add a record in your `/etc/hosts` file that
looks like the following:

```
123.123.123.123 test.com
```

Where `123.123.123.123` is the ip address of your server, and `test.com` is the
domain name you wish to host. *Note that this will work on your computer, but no
one else will be able to visit the site until the DNS records are properly
configured.*

## HTTPS

The `site` command has a sub command that will obtain a certificate from
[letsencrypt](https://letsencrypt.org/) and enable https on a per-site basis.

To obtain a certificate from letsencrypt, you will need to have the DNS records
for your domain properly configured to point to your server, so that you can
prove ownership of that domain.

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
- `ping`: ping the server
- `autorenew`: setup letsencrypt certificates to automatically be renewed
- `addkey`: add an authorized ssh key to the server for your account
- `adduser`: add a user account to the server

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

## Sharing your server with teammates

**For person who setup the server**

1. Make sure you want to give admin access to your teammate.

    The `./server adduser` command will create another user account on the
    server **with admin privileges**.

1. Get your teamate's public ssh key and save it locally

1. Run the appropriate `./server` command

    ```bash
    ./server adduser trustyfriend ~/my_friends_ssh_key.pub
    ```

1. Choose (or have your teamate choose) a password for the new user

**For the teamate being added**

1. Clone this repo

    ```bash
    git clone <url> ~/shared-server
    ```

1. Create a `.env` file with the following contents:

    ```
    ip=<the-servers-ip-address>
    user=<the-user-you-just-created>
    ```

    Replace the values in `<>`s with their appropriate values. Note there needs
    to be **no spaces** around the `=` sign.

    Example `.env`

    ```
    ip=123.123.123.123
    user=codeup
    ```
