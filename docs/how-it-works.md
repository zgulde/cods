# Server Setup Overview

A High-Level Overview of the internals of this project.

If you are curious about how this tool works, or how the server is setup, or
want to contribute, this is the place for you. If you want to know how to use
this tool, you should look at the other guides.

in general:

- automation of sshing into the server and running commands
- Virtual Hosting with both nginx and tomcat
- nginx as a reverse proxy to the tomcat server
- ssl through nginx
- site creation sets up the virtual host on both tomcat and nginx, or just sets
  up nginx to host static files

## This Tool

- the goal is to have virtually zero dependencies, just bash, and a handful of
  common unix tools that are already installed by default on MacOS and should be
  on most linux distros (the script will warn you if they aren't). It should
  also be fast
- Holds its configuration in `~/.config/cods`
- Consist of 2 primary scripts
    - `bin/init.sh`: is used to setup a new server, and will create a command to
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
    bin/init.sh update
    ```

1. Run the `_test` subcommand. This subcommand is not shown in the help message,
   but will provide an interface to the `test` script.

## Server Setup

- Basic Security Hardening
- SSH logins only with public keys (no passwords)
- user accounts (as opposed to running as root)
- no root logins
- firewall denies traffic for everything but ports 22, 80, and 443

### Nginx

- config for each site in `/etc/nginx/sites-available/site-name.tld`
- symlinks in `sites-enabled`
- static content served out of `/srv/site-name.tld/public`
- Will attempt to serve static content first, if not found
    - the request will be passed to tomcat for a java site
    - `404.html` in the webroot will be served
- handles ssl connections when https is setup for a site (as opposed to having
  tomcat do this)

### Tomcat

- version 8.5.x
- Installed in `/opt/tomcat`
- All default webapps removed
- a directory for each site at `/opt/tomcat/site-name.tld`
- site creation modifies `/opt/tomcat/conf/server.xml` to add an entry for
  virtual hosting for that site

### Git Deployment

- a directory in `/srv` is created for every site, e.g. `/srv/site-name.tld`
- this directory contains several things
    - `repo.git`: a bare remote to serve as a deploy remote
    - `config`: a file used by the post-receive hook
- in addition each repo has a post-receive hook that:
    - clones the project
    - looks for build configuration and uses it to build the project
    - deploys build artifacts to the right place
    - can also run a custom user defined script
