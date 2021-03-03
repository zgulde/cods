# Usage

This document provides in-depth documentation on how to use the `cods` tool.

## Table of Contents

* [The `cods` command](#the-cods-command)
* [Commands](#commands)
    * [General Server Commands](#general-server-commands)
    * [Site and Database Management Commands](#site-and-database-management-commands)
    * [Examples](#examples)
* [Site Creation](#site-creation)
* [Database Management](#database-management)
* [HTTPS](#https)
* [Sharing your server](#sharing-your-server)
* [Bash Completion](#bash-completion)

## The `cods` command

The `cods` command allows you to setup a new server, or create a command to
manage a server that you have been granted access to.

While it is the first command you will use, you will be interacting with the
created commands more frequently.

### `init`

When a server is first setup, a command will be created that will be your
interface to that server.

For example, you could run:

```
cods init myserver
```

and this tool will prompt you for information to setup the server, provision it,
then create a command named `myserver` for you to use to interact with the new
server.

Before running the `init` command make sure you have

1. A server with a fresh debian 10 (buster) install
1. Your ssh key on that server with access to the root account
1. The server's ip address ready

When a server is created, a directory inside of `~/.config/cods` is created that
is named after the command name. This directory holds the configuration for the
server, the server credentials, and the default directory for any database
backups you create.

In the scenario above, these files and direcoty would be created:

- `~/.config/cods/myserver/env.sh`: holds the username and ip address of the
  server
- `~/.config/cods/myserver/credentials.txt`: holds the sudo and database
  passwords for the server, and any future generated passwords.
- `~/.config/cods/myserver/db-backups`: default location for the database
  backups you create

### A Note on Credentials

Anything this tool does that sets up user accounts will autogenerate passwords
for the users and store them in the `credentials.txt` file for the server. This
allows easy access to the generated credentials through the server management
command.

**Note that these passwords _are_ stored in plain text on your computer.**

If this is not an acceptable security tradeoff for you, you should remove the
`credentials.txt` file for your server, and update your password storage
solution whenever a new user or database account is generated.

### `add`

To add a server command to interact with an existing server that was setup
elsewhere (either by yourself on another computer or by a teammate) you can use
the `add` command.  See the section on server sharing below.

### `update`

If you update these scripts, you should run

```
cods update
```

to ensure all of your individual server commands are using the most recent
version of the scripts. (This will make sure all of the symlinks for each server
command are pointing to the right place.)

## Commands

The entrypoint for all commands is through the command that the `cods` command
creates. The created command contains various subcommands for performing
different activities on the server.

Broadly speaking, most of the subcommands will ssh into the server and run a
command or a series of commands to achieve the goal of the command. This allows
us to control the server from a local machine, without much need to log in to
the server itself.

For the rest of this guide, we'll assume that the command we created is named
`myserver`. That is, assume we have already run:

```
cods init myserver
```

and successfully setup the server.

To see all the available subcommands, run the `myserver` command without any
arguments:

```
myserver
```

See the [API docs](api.md) for more details and examples for all of the
commands.

## Site Creation

**Prerequisites**

1. One of
    - A java web application with an embedded webserver (e.g. embedded tomcat)
      packaged as a jar
    - a node application
    - a python application
    - A static site (optionally with a build step)
1. For any domain (or subdomain) you want to host on your server, you will need
   to have the DNS records already configured to point to your server's IP.

This setup will allow you to host multiple different sites on your server,
possibly a mix of static and java or node-backed sites, and you can even host
different domains, or multiple different subdomains. For example, you could
setup a java api server at `api.example.com`, and a static site that talks to
the api at `example.com`.

When creating a new site, the `site create` subcommand will check to see if the
DNS records for the given domain point to your server. You will be given a
warning if they do not, but you can go ahead and create the site anyway if you
are still configuring DNS, or waiting for the records to propogate.

If the DNS records are setup, you can pass `--enable-https` to the `site create`
command to also enable https for the site after the site is created.

### Reverse Proxy Sites

Any site that is not a static site will be setup with nginx as a reverse proxy
to your application. This means that both your application and nginx are running
on the server, and when a request comes in, nginx will forward it to your
application.

This configuration allows for virtual hosting, i.e. multiple domains can be
hosted on the same server, and allows nginx to handle https.

#### Port Selection

For Java, Node, and Python sites, you will need to choose a port for your
application to use on the server. Two applications _cannot_ use the same port,
and this tool will prevent you from configuring two separate sites to point to
the same upstream proxy.

The port will need to be chosen when you create the site, and you can view all
the ports that are currently in use by running:

```
myserver ports
```

#### Static Content

For any Java, Node, or Python site, nginx will be setup to serve static content
from a `public` directory within the site directory.

For example, if you created `example.com`, any files on the server in
`/srv/example.com/public` will be served as-is, that is, the requests will not
be passed to your application.

For Java sites, you will probably need to manually manage the contents of this
directory, or ignore it.

For Node or Python sites, if you have a `public` directory at the top level of
your project, any content in this directory will be served directly.

Of course, you can simply choose to ignore this directory and have your
application handle static contents itself.

### Java Site Creation

```bash
myserver site create -d example.com --java -p 8080
```

The port specified will be passed as a command line argument to your application
(in this example, `--server.port=8080`)

When a site is setup, the server will be setup for automated builds and
deployments with git. This is accomplished through a `post-receive` git hook.
This functionality is two-fold: there is a simple setup, and the ability to do
somethings more advanced (see the customizing deployment section below).

When the site is created, an empty git repository will be initialized and named
after the site, for example:

    /srv/example.com/repo.git

You can find the exact git remote, as well as a copy-pastable command for adding
it by running:

```
myserver site info --domain example.com
```

When the repo is pushed to, the post-receive git hook will be triggered, which
will run the build for your project, or run a custom script.

##### `.cods`

To tell the hook how to build your project, you will need to (at a bare
minimum), add a file to your project defining how to build your project, and
where the built `jar` file is output. To do this, create a file named `.cods` in
the root of your project with the following contents:

```bash
BUILD_COMMAND=command_to_execute_to_build_your_project.sh
JAR_FILE=relative/path/to/the_artifact.jar
```

For a spring boot application, the file might look like this:

```bash
BUILD_COMMAND='./mvnw package'
JAR_FILE=target/myblog-0.2.1-SNAPSHOT.jar
```

##### `config` file

In addition to the build configuration, often times you will need to include a
file in the build that is not part of the git repository (e.g. a file with
database credentials). To do that, we can create that file on the server, and
tell the git hook how to find this file. To do this, create the file you want to
be included in the build inside of the directory named after your site inside of
`/srv`, and edit the `config` file found in the same place.

For example, if you needed an `application.properties` file included in the
build for `example.com`, but this file is ignored by git, you would do the
following:

1. ssh into the server and create the production `application.properties` file
   inside the `/srv/example.com/` directory.
1. edit the `/srv/example.com/config` file and define the name of the file to
   be included, as well as where in the project it should be copied to

Take a look at the `config` file or template for more information.

#### Customizing Deployment

If your deploment needs are more complex than what is described above, you can
create a file named `cods.sh` in the root of your project. This file will be
executed after pushing to the deployment remote if a `.cods` file is not found.
This script will be executed after freshly cloning your project, from your
project root, and several environment variables are available to it:

- `SITE_DIR`: the directory that has the repo for your site, along with any
  config files you have setup there (example value: `/srv/example.com`)
- `JAR_TARGET_LOCATION`: Where the built jar needs to end up (example value:
  `/srv/example.com/app.jar`)
- `PUBLIC_DIR`: the directory for static files for your site (example:
  `/srv/example.com/public`)

The cloned repo that is created will be deleted after the `post-receive` hook
finishes running.

Example `cods.sh`

```bash
# exit the script on any errors
set -e
# error on the use of any undefined variables
set -u

# 1. copy over any env specific files you setup on the server
cp $SITE_DIR/application.properties src/main/resources/application.properties
cp $SITE_DIR/secret.file src/main/resources/secret.file
cp $SITE_DIR/env.js src/main/javascript/env.js

# 2. Do any pre-build steps you need to (e.g. compiling css/js assets)
#    Any custom build/deployment logic should go here
echo '[cods.sh] Installing dependencies...'
echo '[cods.sh] > npm install'
npm install
echo '[cods.sh] Building JS...'
echo '[cods.sh] > npm run build'
npm run build

# 3. Build the jar file and put it in the right place
echo '[cods.sh] Building war file...'
echo '[cods.sh] > ./mvnw package'
./mvnw package
mv target/my-awesome-project.jar $JAR_TARGET_LOCATION

# restart the service in order to run the new version of the application
sudo systemctl restart example.com
```

#### Spring Boot Shortcut

You can add `--spring-boot` to the `site create` command:

```
myserver site create --domain example.com --spring-boot
```

This will automatically setup the site's `config` file to match the default
location for the `application.properties` file in a spring boot application.

### Node

```
myserver site create --node --port 3000 --domain my-node-site.com
```

This tool relies on a `npm start` command being defined on your project that
starts the web server.

It is up to you to ensure that the port that your application runs on is the
same as the port that you pass when you run the above command to create the node
site.

A git remote will be created for you, and a `post-receive` hook will be setup so
that when you push the `main` (or `master`) branch to the remote on the server:

1. The new version of the code is checked out, replacing the old version
1. If a file named `cods.sh` exists at the root of the project, it will be
   run, and a variable named `SITE_DIR` will be available to it that contains
   the location of the directory for your site (and the source code).
1. If no `cods.sh` is found, `npm install` will be run
1. The site service will be restarted, i.e. the old `npm run start` process will
   be killed, and it will be started again

See [the example node site for a simplified example](https://github.com/zgulde/cods/tree/master/tests/sample-sites/node).

You can find the git remote and a copy-pastable command to add it to your
project by running:

```
myserver site info --domain my-node-site.com
```

### Python

```
myserver site create --python --port 5000 --domain example-python-site.com
```

In order to host a python site, you'll need to have an executable script named
`start_server.sh` as part of your project. When run, this script should start
your webserver on the port you specified in the above command.

Assuming `server.py` starts the web server, your script might look like this:

```bash
#!/usr/bin/env bash

# ensure the virtualenv directory is present
if [[ ! -d env ]] ; then
    echo 'env directory not found!'
    exit 1
fi

# activate the venv and start the server
source env/bin/activate
python server.py
```

This script should start the application in production mode, for example, you
may use this script to start your application with one of python's wsgi web
servers, e.g. `gunicorn` or `waitress` (I.e. don't start your app in
development/debugging mode!).

You can add a file named `cods.sh` to the root of your project to run custom
code whenever the site is deployed as well. This script will have an environment
variable, `SITE_DIR` available to it, that specifies the location of your source
code on the server.

For example, if your wanted to re-create the virtual environment everytime the
site is deployed, your `cods.sh` script might look like this:

```
#!/usr/bin/env bash

cd $SITE_DIR

echo "[cods.sh] (re-)creating the venv"
echo '[cods.sh] - rm -rf env'
rm -rf env
echo '[cods.sh] python3 -m venv env'
python3 -m venv env
echo '[cods.sh] source env/bin/activate'
source env/bin/activate
echo '[cods.sh] python3 -m pip install -r requirements.txt'
python3 -m pip install -r requirements.txt
```

When you push to the git remote on the server:

1. The new source code will be checked out, replacing the old version
1. If a `cods.sh` file is found, it will be run
1. The currently running server process will be killed, and the server will be
   started again.

You can find the git remote and a copy-pastable command to add it to your
project by running:

```
myserver site info --domain example-python-site.com
```

### PHP

```
myserver site create --php --domain my-php-site.com
```

A git remote will be created for you, and a `post-receive` hook will be setup so
that when you push the `main` (or `master`) branch to the remote on the server:

1. The new version of the code is checked out, replacing the old version.
1. If a file named `cods.sh` exists at the root of the project, it will be
   run, and a variable named `SITE_DIR` will be available to it that contains
   the location of the directory for your site (and the source code).

See [the example php site for a simplified example](https://github.com/zgulde/cods/tree/master/tests/sample-sites/php) or the [example laravel site](https://github.com/zgulde/cods/tree/master/tests/sample-sites/php).

You can find the git remote and a copy-pastable command to add it to your
project by running:

```
myserver site info --domain my-node-site.com
```

Note that for a php site, by default, nginx will not handle 404s, i.e. missing
paths will be sent to your `index.php` file.

### Static Site Creation

```
myserver site create --static --domain example.com
```

Like creating a java site, you can also pass `--enable-https` to activate https
for the site after creating it.

Like a java site, git deployment is setup when you create the site. You can run

```
myserver site info --domain example.com
```

To find the deployment remote.

Deploying a static site is as simple as pushing, when you push, the contents of
your site will be replaced with the most recent contents of your git repository.

[Here is a very minimal example of a static site](https://github.com/zgulde/cods/tree/master/tests/sample-sites/static).

#### 404 Page and Rewrites

If a page is not found, nginx will serve the file named `404.html` from the root
of your project (you should create this file yourself).

If you want to deploy a site that does the routing on the frontend (for example
react + react router), you will probably want your nginx configuration to
rewrite missing files to the index.html page. The nginx config that is setup for
a static site contains comments and commented out configuration that explain how
to do this.

Run the `site info` command to find the path to your site's nginx config file,
then edit the nginx config file (read the comments in the `location /`), and
finally, restart nginx and you should be good to go.

```
myserver site info -d example.com
myserver run sudo nano /etc/nginx/sites-available/example.com
myserver restart --service=nginx
```

#### Static Sites with a Build Process

Of course some static sites have a build process (e.g. webpack or sass). This
tool is setup to accomodate these as well.

##### `.cods` file

If your site can be built with a single command and outputs a single directory,
it is easy to setup automated builds when you deploy.

Create a file named `.cods` at the root of your project. It should have the
following contents:

```
BUILD_COMMAND='npm run build'
OUTPUT_DIR='build'
```

Replacing `npm run build` with the command used to build your project, and
`build` with the name of the directory that contains your site's contents. If
this file is setup, everytime you push to the git remote on the server, the
build command will be run, and the contents of the output directory will be
deployed.

##### Custom Deployment

If there is a file named `cods.sh` in the root of the project, instead of
copying the contents of the repository, the `cods.sh` script will be run
after pushing to the deployment remote.

The script will be run with the current working directory as a fresh clone of
your project. The clone will be removed when the `cods.sh` script finishes
running, so after you preform any build steps, you should move the built files
to the public directory for your project (see example below).

When the script is run, several variables will be available to it:

- `SITE_DIR`: the location on the server that holds the site's configuration
- `PUBLIC_DIR`: the location of files for your site

Example `cods.sh`:

```
# exit script on any error
set -e

echo '[cods.sh] Building...'
npm install
npm run build

echo '[cods.sh] Build Success, deploying...'
mv build/* $PUBLIC_DIR

echo '[cods.sh] All Done!'
```

### Manually Triggering A Build for a Site

You can also manually trigger a build and deploy for a site without needing to
push to the git remote on your server.

```
myserver site build -d example.com
```

This will run the same commands that run when you push to the remote.

## Database Management

While theoretically you might not need to do this, most applications will need
to talk to a database in some form or fashion.

```bash
myserver db create -n some_db -u some_user
```

This command will create a database and a user that has all permissions on that
database (but not any others). The new user's password will be automatically
generated and put into the `credentials.txt` file, which can be viewed by
running:

```bash
myserver credentials
```

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
myserver site enablehttps -d myawesomesite.com
```

After enabling https for a site, you can enable the automatic renewal of certificates:

```bash
myserver autorenew
```

Note that while you do need to enable https for each site individually, you only
need to set up automatic certificate renewal once.

You can also enable https when the site is being created:

```
myserver site create --domain example.com --enable-https
```

This is functionally the same thing as running the `site create` and `site
enablehttps` commands back to back.

## Sharing your server

**For person who setup the server**

1. Make sure you want to give admin access to your teammate.

    The `myserver user add` command will create another user account on the
    server **with admin privileges**.

1. Get your teamate's public ssh key and save it locally

1. Run the appropriate `myserver` command

    ```bash
    myserver user add -u sally -f ~/sallys_ssh_key.pub
    ```

1. Take note of the randomly generated password

1. (Optionally) log into your mysql server and create a database administrator
   account for the new user.

    ```
    myserver db login
    # from mysql
    CREATE USER sally@localhost IDENTIFIED BY 'astrongpassword';
    GRANT ALL ON *.* TO sally@localhost WITH GRANT OPTION;
    ```

**For the teamate being added**

1. Setup the command

    ```
    cods add shared-server
    ```

### Adding a User From Github

You can also add a user to the server based on their github username. For
example, to add `zgulde` to your server, you would run:

```
myserver user add --github-username zgulde
```

This command will create a user with the same login as the github username, a
randomly chosen password, and will use whatever public keys are associated with
the user's github account (you can find these by going to, e.g.,
https://github.com/zgulde.keys).

## Bash Completion

There is a subcommand to generate bash tab completion for the command that is
setup: `bash-completion`. You can add a line like the following to the end of
your `.bashrc` (`.bash_profile` if you're on Mac) like this:

```
eval "$(myserver bash-completion)"
```
