# Server Setup Overview

A High-Level Overview of the internals of this project.

If you are curious about how this tool works, or how the server is setup, or
want to contribute, this is the place for you. If you want to know how to use
this tool, you should look at the other guides.

in general:

- automation of sshing into the server and running commands
- Virtual Hosting with nginx
- nginx as a reverse proxy to various application servers
- static content served w/ nginx
- a systemd service unit is created for each site to handle starting/stopping
  and logging for each site
- https through nginx + letsencrypt
- each application/site runs as it's own user/group

## This Tool

- the goal is to have virtually zero dependencies, just bash, and a handful of
  common unix tools that are already installed by default on MacOS and should be
  on most linux distros (the script will warn you if they aren't). It should
  also be fast
- Holds its configuration in `~/.config/cods`
- Consist of 2 primary scripts
    - `bin/cods.sh`: is used to setup a new server, and will create a command to
      interact with that server (i.e. a symlink to the `server` script)
    - `server`: is the entrypoint to interacting with a setup server, e.g. for
      creating sites and databases
- When a new server is setup, this tool:
    - creates a directory in `~/.config/cods` based on the command name that
      contains the configuration for that server (credentials + ip address,
      username)
    - creates a new symlink to the `server` script
- The `server` script can have multiple symlinks pointing to it for multiple
  different servers. It will figure out which server configuration to use based
  on the name of the symlink (which is the same as the name of the directory in
  `~/.config/cods` that holds the configuration for the server)
- The `server` script has a handful of functions, and delegates to subcommands
  by sourcing the appropriate file inside of `scripts` as necessary
- each script (i.e. subcommand) consists of functions that perform one
  operation
- in general each action handles cli args, then sshs into the server and
  performs one or several operations
- longer operations are broken up into "snippets" (`scripts/snippets`)
- See also the readmes in the `snippets` and `templates` directories

### Testing

is a work in progress

In order to run the tests, you'll need to have a server already setup and the
symlink to the server command should point to a local git checkout of the source
code (i.e. **not** a homebrew installation).

*If you followed the instructions for installing on Linux, you should already be
setup for this.*

Assuming you already have a server setup:

1. Clone this repo into `~/opt/cods` (or elsewhere)

1. Run the update subcommand to change all existing server commands to point to
   your copy of the scripts.

    ```
    bin/cods.sh update
    ```

1. Run the `_test` subcommand. This subcommand is not shown in the help message,
   but will provide an interface to the `test` script.

### Debugging

To debug the `cods` command and any generated server commands, you can set the `_CODS_DEBUG` environment variable.

```
export _CODS_DEBUG=1
```

Now whenever `cods` or a generated server command is run, a file named `cods-debug.log` will be generated in the current working directory that shows all of the commands that are running under the hood.

## Server Setup

- Basic Security Hardening
- SSH logins only with public keys (no passwords)
- user accounts (as opposed to running as root)
- no root logins
- firewall denies traffic for everything but ports 22, 80, and 443
- umask set to 0002 by default (i.e. files are group-writable by default)

### Nginx

- config for each site in `/etc/nginx/sites-available/site-name.tld`
- symlinks in `sites-enabled`
- static content served out of `/srv/site-name.tld/public`
- Will attempt to serve static content first, if not found
    - the request will be passed to the application server
    - `404.html` in the webroot will be served
- handles https connections when https is setup for a site

### Git Deployment

- a directory in `/srv` is created for every site, e.g. `/srv/site-name.tld`
- this directory contains several things
    - `repo.git`: a bare remote to serve as a deploy remote
    - `config`: a file used by the post-receive hook
- in addition each repo has a post-receive hook that:
    - for a java project:
        - clones the project
        - looks for build configuration and uses it to build the project
        - deploys build artifacts to the right place
    - for a static site/node project:
        - checks out the most recent version of the code
    - restarts the application server
    - can also run a custom user defined script

### Systemd

- A service unit file is created for each domain/application on the server
- commands used to start the application (ExecStart):
    - node: `npm start`
    - java: `java -jar app.jar` (this jar file is built by the post-recieve hook
      and put in the right place)
- stdout and stderr of each application server is logged
- allows us to use `systemctl` to start/stop/restart the application, or start
  it again when it fails (e.g. `systemctl status example.com` or `systemctl
  restart example.com`)
- allows us to hook into systemd's handling of log files so we don't have to
  worry about curation, timestamps, or rotaion
    - `journalctl -u example.com` to view a site/application's logs with
      timestamps
    - the `site logs` server subcommand is a shortcut to this
- each service is run by a user + group that is specific to that site
- sudo permissions are setup so that admins can manage (i.e. start/stop/restart
  and view log files) the service w/o a password
