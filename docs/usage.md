# Usage

The setup script is intended to setup and secure a server with a fresh install
of Ubuntu 16.04 and only a root account.

## Table of Contents

* [Commands](#commands)
* [Site Creation](#site-creation)
* [Git Deployment](#git-deployment)
* [HTTPS](#https)
* [Sharing your server with teammates](#sharing-your-server-with-teammates)
* [Uploads](#uploads)
* [Bash Tab Completion](#bash-completion)

**Prerequisites**

1. A java web application packaged as a war that can be served by Tomcat.
1. A server with a fresh ubuntu 16.04 install
1. Your ssh key on that server with access to the root account
1. For any domain (or subdomain) you want to host on your server, you will need
   to have the DNS records already configured to point to your server's IP.

When the server is first setup, a `.env` file will be created that contains the
name of the account you created and the server's ip address. All of the other
commands for managing the server will check for this `.env` file to make sure
the server is setup before trying to do anything.

Broadly speaking, most of the commands will ssh into the server and run a command
or a series of commands to achieve the goal of the command. This allows us to
control the server from a local machine, without much need to log in to the
server itself.

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
Have the ip address of your server handy, and then run the `server` script. The
script will detect that we don't have anything setup and run the first time
setup process.

The script will also provide a command that you can run to interact with your
server, based on the name of the directory you cloned this project into. For
example, if you cloned this project into a directory named `myserver`, the setup
script will create a command named `myserver`.

## Commands

The entrypoint for all commands is through the command that the setup script
creates (really this is just a symlink to the `server` script for convenience).
It contains various subcommands for performing different activities on the
server. The first time this script is run it will perform the initial server
setup and provisioning. Once the server is setup you will be able to run the
various subcommands.

For the rest of this guide, we'll assume that the command we created is named
`myserver`.

To see all the available subcommands, run the `myserver` command without any
arguments:

```
myserver
```

The same applies for the `site` and `db` subcommands, to see their available
subcommands, just run them by themselves:

```
myserver site
myserver db
```

Any subcommands that require arguments can be run without arguments to see
detailed help for the command.

All command line arguments have a long form, and most have a short form as well.
You can pass commnad line arguments in one of 3 ways:

```
-a value
--arg value
--arg=value
```

In general, any password prompts will be for your server admin password (i.e.
your sudo password), unless you are running the `db` subcommand, in which case
you will need to enter the database administrator password.

### General Server Commands

- `login`: log in to the server
- `upload`: upload a file to the server (will default to the user's home
  directory if no destination path is specified)
- `info`: view some general information about your server
- `restart`: restart a specific service. Shortcut for logging in and running
  `sudo systemctl restart ...`
- `reboot`: reboot the server
- `ping`: ping the server
- `autorenew`: setup letsencrypt certificates to automatically be renewed
- `addkey`: add an authorized ssh key to the server for your account
- `adduser`: add an admin user account to the server
- `log:cat`: view the contents of the tomcat log file, `/opt/tomcat/logs/catalina.out`
- `log:tail`: watch the contents of the tomcat log file in real-time (`tail -f`)
- `bash-completion`: generate the bash completion script for the command
- `credentials`: view the auto-generated credentials for your server

### Site and Database Management Commands

`site`

- `list`: view the sites that are currently setup on the server
- `create`: create a new site
- `build`: trigger a build and deployment of an existing site
- `remove`: remove a site. Will remove the nginx config for the site, as well as
  any previously deployed `war`s
- `enablessl`: enable https for a site
- `info`: show general information for a site
- `deploy`: deploy a `war` file for an individual site

`db`

- `login`: login to your mysql database
- `list`: list the databases that exist on your server
- `create`: create a new database and a user with privileges on only that
  database
- `backup`: create a backup of a database
- `remove`: remove a database and user

### Examples

For more examples, you can run any command that accepts arguments without
arguments and a help message will be shown. For example, to see the help for the
`upload` subcommand, run:

```
myserver upload
```

#### View all the available subcommands

```bash
myserver
```

#### View the commands for database managment

```bash
myserver db
```

#### Login to the server

```bash
myserver login
```

#### Login to the database

```bash
myserver db login
```

#### Create a site

```bash
myserver site create -d example.com
```

#### Upload a file to a site's uploads directory

```bash
myserver upload -f ~/Downloads/kittens.png -d /var/www/example.com/uploads
```


## Site Creation

This setup will allow you to host multiple different domains on each server. For
each site you wish to host, you will need to:

1. Setup the DNS Records for that domain to point to your server
1. Create the site
1. (Probably) Create a database and user for the application
1. Deploy a `war` that contains the application

### DNS Records + Site Creation

```bash
myserver site create example.com
```

This command will setup virtual hosts with both tomcat and nginx for the domain
name you have provided.

When creating a new site, the `site create` subcommand will check to see if the
DNS records for the given domain point to your server. You will be given a
warning if they do not, but you can go ahead and create the site anyway if you
are still configuring DNS, or waiting for the records to propogate. To test your
site under these conditions, you can add a record in your `/etc/hosts` file that
looks like the following:

```
123.123.123.123 test.com
```

Where `123.123.123.123` is the ip address of your server, and `test.com` is the
domain name you wish to host. *Note that this will work on your computer, but no
one else will be able to visit the site until the DNS records are properly
configured.*

### Create Database + User

While theoretically you might not need to do this, most applications will need
to talk to a database in some form or fashion.

```bash
myserver db create -d some_db -u some_user
```

This command will create a database and a user that has all permissions on that
database (but not any others).

You will be prompted for a password for the new database user.

At this point you may wish to log into the server to do any database setup
required for your application.

### Deploy The `war`

This will `scp` the file to the appropriate location on your server. Once you
run this command, you should be able to see your site live!

```bash
myserver site deploy -d example.com -f /path/to/the/war/file.war
```

Of course, before you run this you will need to have packaged your application
as a war. For example, if you are using maven:

```bash
# from the root directory
mvn package
```

or with maven wrapper

```bash
./mvnw package
```

Alternatively, you can setup automated deployments with git.

## Git Deployment

When a site is setup, the server will also be setup for automated builds and
deployments with git. This is accomplished through a `post-receive` git hook.
This functionality is two-fold: there is a simple setup, and the ability to do
somethings more advanced (see the customizing deployment section below).

When the site is created, an empty git repository will be initialized and named
after the site, for example:

    /srv/example.com/repo.git

You'll see instructions for adding this as a remote to an existing project in
the output of the command that sets up the site.

When the repo is pushed to, the post-receive git hook will be triggered, which
will run the build for your project, or run a custom script.

To tell the hook how to build your project, you will need to (at a bare
minimum), add a file to your project defining how to build your project, and
where the built `war` file lives. To do this, create a file named
`.build_config` in the root of your project with the following contents:

`.build_config`

```bash
BUILD_COMMAND=command_to_execute_to_build_your_project.sh
WAR_FILE=relative_path_to_the_artifact.war
```

In addition, often times you will need to include a file in the build that is
not part of the git repository (e.g. a file with database credentials). To do
that, we can create that file on the server, and tell the git hook how to find
this file. To do this, create the file you want to be included in the build
inside of the directory named after your site inside of `/srv`, and edit the
`config` file found in the same place.

For example, if you needed an `application.properties` file included in the
build for `example.com`, but this file is ignored by git, you would do the
following:

1. ssh into the server and create the production `application.properties` file
   inside the `/srv/example.com/` directory.
1. edit the `/srv/example.com/config` file and define the name of the file to
   be included, as well as where in the project it should be copied to

Take a look at the `config` file or template for more information.

### Customizing Deployment

If your deploment needs are more complex than what is described above, you can
create a file named `install.sh` in the root of your project. This file will be
executed if a `.build_config` file is not found. This script will be executed
from your project root, and several environment variables are available to it:

- `SITE_DIR`: the directory that has the repo for your site, along with any
  config files you have setup there (example value: `/srv/example.com`)
- `WAR_TARGET_LOCATION`: Where the built war needs to end up so that tomcat can
  find it (example value: `/opt/tomcat/example.com/ROOT.war`)

Example `install.sh`

```bash
# exit the script on any errors
set -e

# 1. copy over any env specific files you setup on the server
cp $SITE_DIR/application.properties src/main/resources/application.properties
cp $SITE_DIR/secret.file src/main/resources/secret.file
cp $SITE_DIR/env.js src/main/javascript/env.js

# 2. Do any pre-build steps you need to (e.g. compiling css/js assets)
#    Any custom build/deployment logic should go here
echo '[install.sh] Installing dependencies...'
echo '[install.sh] > npm install'
npm install
echo '[install.sh] Building JS...'
echo '[install.sh] > npm run build'
npm run build

# 3. Build the war file and put it in the right place
echo '[install.sh] Building war file...'
echo '[install.sh] > ./mvnw package'
./mvnw package
mv target/my-awesome-project.war $WAR_TARGET_LOCATION
```

### Manually Triggering A Build

You can also manually trigger a build and deploy without needing to push to the
git remote on your server.

```
myserver site build -d example.com
```

This will run the same script that runs when you push to the remote.

## HTTPS

The site management command has a sub command that will obtain a certificate
from [letsencrypt](https://letsencrypt.org/) and enable https on a per-site
basis.

To obtain a certificate from letsencrypt, you will need to have the DNS records
for your domain properly configured to point to your server, so that you can
prove ownership of that domain.

**Before using this command make sure you agree to the [Lets Encrypt Subscriber
Agreement](https://letsencrypt.org/documents/LE-SA-v1.1.1-August-1-2016.pdf).**

Simply run

```bash
myserver site enablessl -d myawesomesite.com
```

After enabling https for a site, you can enable the automatic renewal of certificates:

```bash
myserver autorenew
```

Note that while you do need to enable https for each site individually, you only
need to set up automatic certificate renewal once.

## Sharing your server with teammates

**For person who setup the server**

1. Make sure you want to give admin access to your teammate.

    The `myserver adduser` command will create another user account on the
    server **with admin privileges**.

1. Get your teamate's public ssh key and save it locally

1. Run the appropriate `myserver` command

    ```bash
    myserver adduser -u sally -f ~/sallys_ssh_key.pub
    ```

1. Choose (or have your teamate choose) a password for the new user

1. (Optionally) log into your mysql server and create a database administrator
   account for the new user.

    ```
    myserver db login
    # from mysql
    CREATE USER sally@localhost IDENTIFIED BY 'astrongpassword';
    GRANT ALL ON *.* TO sally@localhost WITH GRANT OPTION;
    ```

**For the teamate being added**

1. Clone this repo

    ```bash
    git clone https://github.com/gocodeup/tomcat-setup ~/shared-server
    ```

1. Setup the command

    ```
    ln -s ~/shared-server/server ~/opt/bin/shared-server
    ```

    Replacing `shared-server` with the name of the directory you cloned this
    project into

    *If you've run the `./server` before for a different server, go to the next
    step.*

    Make sure `~/opt/bin` in on your `PATH`. You should have a line like this:

    ```
    export PATH="$PATH:$HOME/opt/bin"
    ```

    In your `.bashrc` (Linux) or `.bash_profile` (Mac)

1. Create a `.env` file

    Create a file named `.env` inside the project you just cloned:

    ```
    nano ~/shared-server/.env
    ```

    This file should have the following contents:

    ```
    ip=<the-servers-ip-address>
    user=<the-user-you-just-created>
    ```

    Replace the values in `<>`s with their appropriate values. *Note there needs
    to be **no spaces** around the `=` sign.*

    An example `.env` file might look like this:

    ```
    ip=123.123.123.123
    user=sally
    ```

## Uploads

Nginx is set up to intercept any requests to `/uploads` and try to serve them
out of the uploads directory for your site, which is located at

```
/var/www/example.com/uploads
```

You can setup your application to interact with this directory, and use the
`upload` subcommand to manually put files here.

## Development Webserver

There is a subcommand of server, `devserver` that can be used to start up nginx
locally. This will simulate the nginx setup running in production, but it is up
to you to start the tomcat server locally on port 8080.

```bash
myserver devserver my-project.dev
```

see the built in help

```bash
myserver devserver
```

for more details.

*Currently this setup assumes the upstream server is running locally on port
8080, and this is not configurable.*

## Bash Completion

There is a subcommand to generate bash tab completion for the command that is
setup: `bash-completion`. You can add a line like the following to the end of
your `.bashrc` (`.bash_profile` if you're on Mac) like this:

```
eval "$(myserver bash-completion)"
```
