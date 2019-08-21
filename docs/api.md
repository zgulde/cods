# API Documentation

The document explains how all of the commands and subcommands within `cods`
work.

See also built-in help.

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
- `ports`: view the ports that are being reverse-proxied to by nginx
- `bash-completion`: generate the bash completion script for the command
- `credentials`: view the auto-generated credentials for your server

### Site and Database Management Commands

`site`

- `list`: view the sites that are currently setup on the server
- `create`: create a new site
- `build`: trigger a build and deployment of an existing site
- `logs`: view the log files for a site
- `remove`: remove a site. Will remove the nginx config for the site, as well as
  any previously deployed `jar`s
- `enablehttps`: enable https for a site
- `info`: show general information for a site

`db`

- `login`: login to your mysql database
- `list`: list the databases that exist on your server
- `create`: create a new database and a user with privileges on only that
  database
- `backup`: create a backup of a database
- `remove`: remove a database and user


* [The `cods` command](#the-cods-command)
    * [`init`](#init)
    * [`add`](#add)
    * [`update`](#update)
    * [`help`](#help)
* [`myserver` - A Command Created By Cods](#myserver---a-command-created-by-cods)
    * [General Server Commands](#general-server-commands)
        * [`info`](#info)
        * [`login`](#login)
        * [`ports`](#ports)
        * [`ping`](#ping)
        * [`swapon`](#swapon)
        * [`autorenew`](#autorenew)
        * [`reboot`](#reboot)
        * [`run`](#run)
        * [`pipe`](#pipe)
        * [`credentials`](#credentials)
        * [`destroy`](#destroy)
        * [`switch-java-version`](#switch-java-version)
        * [`bash-completion`](#bash-completion)
        * [`upload`](#upload)
        * [`restart`](#restart)
        * [`addkey`](#addkey)
    * [`site` Commands for site management](#site-commands-for-site-management)
        * [`list`](#list)
        * [`create`](#create)
        * [`remove`](#remove)
        * [`build`](#build)
        * [`enablehttps`](#enablehttps)
        * [`info`](#info-1)
        * [`logs`](#logs)
    * [`db` Commands for database management](#db-commands-for-database-management)
        * [`login`](#login-1)
        * [`list`](#list-1)
        * [`create`](#create-1)
        * [`remove`](#remove-1)
        * [`backup`](#backup)
    * [`user` Commands for user management](#user-commands-for-user-management)
        * [`add`](#add-1)
        * [`remove`](#remove-2)

## The `cods` command

### `init`

The `init` subcommand is used to provision a server and setup a local server
command. The server must be "fresh" (i.e. not setup by any other provisioning
tools), and you must have root ssh access to the server.

The name of the server command bust be provided, then any optional arguments.

**Arguments**

- `-i` or `--ip`: (optional) the ip address of the server. If not provided, you
  will be prompted for it.
- `-u` or `--user`: (optional) the username to setup for yourself on the server.
  If not provided, you will be prompted for it.
- `-e` or `--email`: (optional) your email address. If note provided, you will
  be prompted for it.
- `--root-user`: username of the user that has root access to the server.
  Defaults to `root`.

**Examples**

- Create a command named `myserver`

    ```
    cods init myserver
    ```

    You will be prompted for the server's ip address, a username for yourself,
    and your email address.

- Create a command named `myserver`

    ```
    cods init myserver --ip 123.123.123.123 --user codeup --email info@codeup.com
    ```

    Here you will **not** be prompted for the server's ip address, a username
    for yourself, and your email address because they were provided as command
    line arguments.

- Create a `myserver` command using a different root user for the initial setup

    ```
    cods init myserver --root-user debian
    ```

### `add`

The `add` subcommand is used to create a local server command for an existing
server. You will need to have ssh access to an existing user account on the
server.

You might use this command if:

- you want to get access to a shared server that your teammate setup and gave
  you an account on
- you want to be able to access from your desktop pc a server that you setup on
  your laptop

The name of the server command bust be provided, then any optional arguments.

**Arguments**

- `-i` or `--ip`: (optional) the ip address of the server. If not provided, you
  will be prompted for it.
- `-u` or `--user`: (optional) the username to setup for yourself on the server.
  If not provided, you will be prompted for it.

**Examples**

- Create a command named `myserver`

    ```
    cods add myserver
    ```

    You will be prompted for the server's ip address and your username.

- Create a command named `myserver`

    ```
    cods init myserver --ip 123.123.123.123 --user codeup --email info@codeup.com
    ```

    Here you will **not** be prompted for the server's ip address or your
    username for yourself because they were provided as command line arguments.

### `update`

Updates any existing server commands to the most recent version of the `cods`
scripts.

You should run this after you update `cods`.

**Example**

```
cods update
```

### `help`

Launch the interactive help system.

**Example**

```
cods help
```

## `myserver` - A Command Created By Cods

While `cods` can create commands with any name, for the rest of this document we
will assume we are working with a command named `myserver`.

### General Server Commands

#### `info`

Show general information about the server

**Example**

```
myserver info
```

#### `login`

Launch an interactive shell logged in to your server

**Example**

```
myserver login
```

#### `ports`

Show the ports that are currently in use by sites that are setup on the server.

**Example**

```
myserver ports
```

This will output something like the following:

```
8000 example.com
5000 blog.example.com
```

Where the number to the left of the domain indicates the port that the
site's application is running on.

#### `ping`

Pings the server

#### `swapon`

Enable a swap file on the server. You may need to do this if you are using a
lower-end droplet and are getting out of memory errors.

**Example**

```
myserver swapon
```

#### `autorenew`

Setup all https certificates to be automatically renewed.

```
myserver autorenew
```

This will setup a cron-job that will have the letsencrypt client renew any
certificates that need to be renewed.

It is safe to run this command multiple timesl if the cron job is already setup,
it will do nothing.

#### `reboot`

Reboot the server

#### `run`

Run arbitrary command on the server.

**Examples**

- Edit a file on the server with `nano`

    ```
    myserver run nano /srv/example.com/application.properties
    ```

- Edit the nginx configuration for a site with `nano`

    ```
    myserver run sudo nano /etc/nginx/sites-available/example.com
    ```

- View the running processes on the server

    ```
    myserver run htop
    ```

- View the current time on the server

    ```
    myserver run date
    ```

#### `pipe`

Run a command on the server in a non-interactive environment (a pty will *not*
be allocated). This can be useful for transferring binary data to the server.

#### `credentials`

View the credentials file for your server. This file contains all the
autogenerated usernames and passwords for this server.

You can also use this command to view the location of the credentials file or
modify it.

**Examples**

- View the autogenerated credentials

    ```
    myserver credentials
    ```

- View the path to the credentials file, i.e. where the file is located on your
  laptop

    ```
    myserver credentials path
    ```

- Edit the credentials file

    ```
    myserver credentials edit
    ```

    The editor that the file is opened in is based on the `EDITOR` environment
    variable.

- Add another entry to the credentials file

    ```
    myserver credentials add myuser: password123
    ```

    Anything after the word `add` will be appended to the credentials file.

#### `destroy`

Remove the server command from your laptop. This command will destroy any
knowledge `cods` has about the server locally, including any database backups.

Before destroying the server, you will need to type a confirmation message so
that the process cannot happen accidentaly.

Note that this *will not* remove the VPS you created on Digital Ocean (or other
hosting provider).

#### `switch-java-version`

Change the version of java that is running on the server. At the time of writing
the choices are the 2 LTS java versions, 8 and 11.

**Example**

```
myserver switch-java-version
```

You will be presented with a menu where you can choose the number that
corresponds to the java installation you wish to use.

#### `bash-completion`

Outputs bash shell code that can be used to enable tab completion for the
`myserver` command. You shouldn't really run this command directly, but rather,
evaluate it's output.

**Example**

Running the code below will enable tab completion for the current terminal
session:

```
eval "$(myserver bash-completion)"
```

Now type:

```
myserver <TAB><TAB>
```

You will notice that all subcommands and any command arguments will be
autocompleted.

To make this tab completion persistent, add the line above with `eval` to your
`~/.bash_profile` (or `~/.bashrc` if you're on Linux) file.

#### `upload`

Upload a file from your laptop to the server.

Optionally specify a destination, otherwise will default to your home directory.

**Arguments**

- `-f` or `--file`: path to the file to upload
- `-d` or `--destination`: (optional) destination for the file on the server

**Examples**

- Upload the `mycat.png` file in your downloads directory to the `uploads`
  folder within the `public` directory for `example.com`

    ```
    myserver upload -f ~/Downloads/mycat.png -d /srv/example.com/public/uploads/mycat.png
    ```

- Upload a migration SQL script to your server using a relative file path

    ```
    myserver upload --file=migration.sql
    ```

- Upload a seeder SQL script using an absolute file path

    ```
    myserver upload --file ~/IdeaProjects/blog/seeder.sql
    ```

#### `restart`

Restart a service that is running on the server.

**Arguments**

- `-s` or `--service`: name of the service to restart

**Example**

Restart the `nginx` service

```
myserver restart --service nginx
```

#### `addkey`

Add an additional authorized ssh key to your account.

**Arguments**

- `-f` or `--sshkeyfile`: local path to the public ssh key to add

**Examples**

Add another public key file that you have saved locally

```
myserver addkey -f ~/.ssh/my-other-computer.pub
```

### `site` Commands for site management

#### `create`

Setup the server to host a new site.

You must provide a domain name and a site type.

For java, node, and python sites, a port number (that isn't already in use) must
be provided.

**Arguments**

- `-d` or `--domain`:  domain name of the site to create
- `--static`: setup a static site
- `--java`: - setup a java site
- `--node`:  setup a node site
- `--python`:  setup a python site
- `--php`: setup a php site
- `-p` or `--port`: port number that the application will run on
- `--spring-boot`: (optional) perform extra configuration for a spring-boot site
- `--enable-https`: (optional) enable https after setting up the site (see the
  `enablehttps` subcommand for more details)

**Examples**:

- setup a static site on `example.com`

    ```
    myserver site create -d example.com --static
    ```

- setup a spring boot java site that runs on port 8000

    ```
    myserver site create --domain=example.com --java -p 8000 --spring-boot
    ```

- setup a node site on port 3000 and enable https for it

    ```
    myserver site create --domain=example.com --node --port=3000 --enable-https
    ```

- setup a python site on port 5000

    ```
    myserver site create --domain example.com --python --port 5000
    ```

#### `list`

List the sites that are currently setup on the server.

**Example**

```
myserver site list
```

#### `remove`

Remove a site from the server.

Confirmation will be required before the site is removed. Note that this will
*not* remove any databases associated with the site.

**Arguments**

- `-d` or `--domain` domain name to remove

**Example**

```
myserver site remove --domain example.com
```

#### `build`

Trigger a build for a site.

This will trigger the same process that runs whenever a new version is pushed to
your production git remote.

This can be useful if, for example, you made a typo when setting up database
credentials for the site and need to restart the site, but didn't make any
changes to the underlying application code.

**Arguments**

- `-d` or `--domain` domain name to trigger the build for

**Example**

```
myserver site build -d example.com
```

#### `enablehttps`

Enable https for a site.

Before running this command, you should make sure that the DNS records for your
domain are configured to point to your server, otherwise this command *will*
fail.

On running this command, an https certificate will be obtained using
letsencrypt, and your site will be setup to be served only over https (i.e. not
http.)

**Arguments**

- `-d` or `--domain`: domain name of the site to enable https for

**Example**

```
myserver site enablehttps -d example.com
```

#### `info`

Show various information about a site.

#### `logs`

Show the logs for a site.

This command is only useful for java, node, and python site types.

**Arguments**

- `-d` or `--domain`: Name of the domain to check logs for
- `-f` or `--follow`: Watch the log file in real-time (press C-c to quit)

**Examples**

- dump the entire log file for `example.com` out to your terminal

    ```
    myserver site logs -d example.com
    ```

- watch the log file for example.com in real-time

    ```
    myserver site logs -d example.com -f
    ```

- save the logs for `example.com` to a file named `example.com.log`

    ```
    myserver site logs --domain example.com > example.com.log
    ```

### `db` Commands for database management

All of the commands here will require your database administrator password when
run.

#### `login`

Login to the database; start an interactive session.

**Example**

```
myserver db login
```

#### `list`

List the existing databases on the server

```
myserver db list
```

#### `create`

Create a database and user that has permissions only on that database.

A random password will be generated for the new user and stored in the
credentials file for the server.

After the user is created, the user's password can again be viewed by running:

```
myserver credentials
```

**Arguments**

`-n` or `--name`: name of the database to create
`-u` or `--user`: name of the database user to create

**Examples**

```
myserver db create -n example_db -u example_user
myserver db create --name=test_db --user=test_user
```

#### `remove`

Drop a database from the server.

**Arguments**

`-n` or `--name`: name of the database to remove
`-u` or `--user`: name of the user to remove

**Examples**

```
myserver db remove -n example_db -u example_user
myserver db remove --name test_db --user test_user
```

#### `backup`

Create a backup of a database.

The database backup will be stored locally, that is, on your laptop. You can
specify a path for the database backup or it will default to
`~/.config/cods/myserver/db-backups/DATE-DB-backup.sql`. Where `DATE` and `DB`
are replaced with the current date/time and database name, respectively.

**Arguments**

- `-n` or `--name`:  name of the database to backup
- `-o` or `--outfile`: (optional) where to save the sql dump

**Examples**

- Save a backup of `example_db` to the default location

    ```
    myserver db backup -n example_db
    ```

- save a backup of `example_db` to a location in the home directory

    ```
    myserver db backup -n example_db -o ~/my-db-dump.sql
    ```

- Save a backup of `blog_db` to a relative path

    myserver db backup --name=blog_db --outfile=./src/main/sql/blog-backup.sql


### `user` Commands for user management

This command allows you to grant other humans access to your server

#### `add`

Add a new admin user to the server.

Users can be added either by:

- specifying a username and a path to the user's public ssh key
- specifying a github username, and the user's public keys will be pulled from
  github

**Arguments**

- `-f` or `--sshkeyfile`: path to the new user's public key
- `-u` or `--username`: username for the new user
- `--github-username`: github username to lookup public keys; will also be used as
  server username

**Examples**

```
myserver user add -u sally -f ~/sallys-ssh-key.pub
myserver user add --username=sally --sshkeyfile=~/key.pub
myserver user add --github-username gocodeup
```


#### `remove`

Remove an existing user from the server.

**Arguments**

- `-u` or `--username`: username of the user to remove

**Examples**

```
myserver user remove -u sally
myserver user remove --username=sally
```

