# Usage

* [The `cods` command](#the-cods-command)
* [Commands](#commands)
* [Site Creation](#site-creation)
    * [Java Site Creation](#java-site-creation)
    * [Static Site Creation](#static-site-creation)
* [HTTPS](#https)
* [Sharing your server with teammates](#sharing-your-server-with-teammates)
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

1. A server with a fresh ubuntu 16.04 install
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

### `share`

If a teammate of yours granted you access to a shared server, you can use the
`share` command to create a command to interface with the shared server. See the
section on server sharing below.

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

**Prerequisites**

1. One of
    - A java web application packaged as a war that can be served by Tomcat.
    - A static site (optionally with a build step)
1. For any domain (or subdomain) you want to host on your server, you will need
   to have the DNS records already configured to point to your server's IP.

This setup will allow you to host multiple different sites on your server,
possibly a mix of static and java-backed sites, and you can even host different
domains, or multiple different subdomains. For example, you could setup a java
api server at `api.example.com`, and a static site that talks to the api at
`example.com`.

When creating a new site, the `site create` subcommand will check to see if the
DNS records for the given domain point to your server. You will be given a
warning if they do not, but you can go ahead and create the site anyway if you
are still configuring DNS, or waiting for the records to propogate.

If the DNS records are setup, you can pass `--enable-ssl` to the `site create`
command to also enable https for the site after the site is created.

### Java Site Creation

```bash
myserver site create -d example.com
```

This command will setup virtual hosts with both tomcat and nginx for the domain
name you have provided. Nginx will be setup to serve files out of a public
directory (located at `/srv/example.com/public`), and if the file is not found,
to pass the request off to tomcat.

If you have a pre-built `war` file, you can use this command to `scp` the file
to the appropriate location on your server.

```bash
myserver site deploy -d example.com -f /path/to/the/war/file.war
```

Alternatively, you can setup automated deployments with git.

#### Git Deployment

When a site is setup, the server will also be setup for automated builds and
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

##### `.build_config`

To tell the hook how to build your project, you will need to (at a bare
minimum), add a file to your project defining how to build your project, and
where the built `war` file lives. To do this, create a file named
`.build_config` in the root of your project with the following contents:

```bash
BUILD_COMMAND=command_to_execute_to_build_your_project.sh
WAR_FILE=relative_path_to_the_artifact.war
```

##### `config` file

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

#### Customizing Deployment

If your deploment needs are more complex than what is described above, you can
create a file named `install.sh` in the root of your project. This file will be
executed after pushing to the deployment remote if a `.build_config` file is not
found. This script will be executed after freshly cloning your project, from
your project root, and several environment variables are available to it:

- `SITE_DIR`: the directory that has the repo for your site, along with any
  config files you have setup there (example value: `/srv/example.com`)
- `WAR_TARGET_LOCATION`: Where the built war needs to end up so that tomcat can
  find it (example value: `/opt/tomcat/example.com/ROOT.war`)
- `PUBLIC_DIR`: the directory for static files for your site (example:
  `/srv/example.com/public`)

The cloned repo that is created will be deleted after the `post-receive` hook
finishes running.

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

#### Spring Boot Shortcut

You can add `--spring-boot` to the `site create` command:

```
myserver site create --domain example.com --spring-boot
```

This will automatically setup the site's `config` file to match the default
location for the `application.properties` file in a spring boot application.

### Static Site Creation

```
myserver site create --static --domain example.com
```

Like creating a java site, you can also pass `--enable-ssl` to activate https
for the site after creating it.

Like a java site, git deployment is setup when you create the site. You can run

```
myserver site info --domain example.com
```

To find the deployment remote.

Deploying a static site is as simple as pushing, when you push, the contents of
your site will be replaced with the most recent contents of your git repository.

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

Similarly to java deployment, if there is a file named `install.sh` in the root
of the project, instead of copying the contents of the repository, the
`install.sh` script will be run after pushing to the deployment remote.

The script will be run with the current working directory as a fresh clone of
your project. The clone will be removed when the `install.sh` script finishes
running, so after you preform any build steps, you should move the built files
to the public directory for your project (see example below).

When the script is run, several variables will be available to it:

- `SITE_DIR`: the location on the server that holds the site's configuration
- `PUBLIC_DIR`: the location of files for your site

Example `install.sh`:

```
# exit script on any error
set -e

echo '[install.sh] Building...'
npm install
npm run build

echo '[install.sh] Build Success, deploying...'
mv build/* $PUBLIC_DIR

echo '[install.sh] All Done!'
```

### Manually Triggering A Build for a Site

You can also manually trigger a build and deploy for either a static site or a
java site without needing to push to the git remote on your server.

```
myserver site build -d example.com
```

This will run the same script that runs when you push to the remote.

### Database Management

While theoretically you might not need to do this, most applications will need
to talk to a database in some form or fashion.

```bash
myserver db create -n some_db -u some_user
```

This command will create a database and a user that has all permissions on that
database (but not any others). The new user's password will be automatically
generated and put into the `credentials.txt` file.

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

You can also enable https when the site is being created:

```
myserver site create --domain example.com --enable-ssl
```

This is functionally the same thing as running the `site create` and `site
enablessl` commands back to back.

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

1. Setup the command

    ```
    cods share shared-server
    ```

## Uploads

Nginx is set up to first try to serve static files out of the public directory
for a site, before passing the request to the tomcat web server.

One example of putting this to use would be to setup an `uploads` directory
inside the public directory, as this directory and its contents will persist
even if you deploy a new `.war` file. For example, you could tell your
application to write uploaded files to

```
/srv/example.com/public/uploads
```

Then any url like `https://example.com/uploads/123abc.png` will be served out of
the uploads directory.

## Bash Completion

There is a subcommand to generate bash tab completion for the command that is
setup: `bash-completion`. You can add a line like the following to the end of
your `.bashrc` (`.bash_profile` if you're on Mac) like this:

```
eval "$(myserver bash-completion)"
```
