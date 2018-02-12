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

## Server

- Basic Security Hardening
- SSH logins only with public keys (no passwords)
- user accounts (as opposed to running as root)
- no root logins
- firewall denies traffic for everything but ports 22, 80, and 443

## Nginx

- all config is "typical"
- config for each site in `/etc/nginx/sites-available/site-name.tld`
- symlinks in `sites-enabled`
- static content served out of `/var/www/site-name.tld`
- For java sites, will intercept any requests to `/uploads` and serve static
  files from `/var/www/site-name.tld/uploads`, otherwise will pass requests off
  to `localhost:8080`, where tomcat is listening
- handles ssl connections when https is setup for a site (as opposed to having
  tomcat do this)

## Tomcat

- version 8.5.x
- Installed in `/opt/tomcat`
- All default webapps removed
- a directory for each site at `/opt/tomcat/site-name.tld`
- site creation modifies `/opt/tomcat/conf/server.xml` to add an entry for
  virtual hosting for that site

## Git Deployment

- a directory in `/srv` is created for every site, e.g. `/srv/site-name.tld`
- this directory contains several things
    - `repo.git`: a bare remote to serve as a deploy remote
    - `config`: a file used by the post-receive hook
- in addition each repo has a post-receive hook that:
    - clones the project
    - looks for build configuration and uses it to build the project
    - deploys build artifacts to the right place
    - can also run a custom user defined script

## These Scripts

- the goal is to have virtually zero dependencies, just bash, and a handful of
  common unix tools that are already installed by default on MacOS and should be
  on most linux distros (the script will warn you if they aren't). It should
  also be fast
- create a `.env` file when initially setup that contains the username and ip
  address. This file is necessary for all functionality and determines whether
  or not we need to run the initial setup
- puts a symlink to the executable entrpoint of this setup in `~/opt/bin` to
  make interacting with the server easy
- consist of an entrypoint (`server`) which delegates to subcommands (in
  `scripts/`) as necessary
- each script (i.e. subcommand) consists of functions that perform one
  operation
- in general each action handles cli args, then sshs into the server and
  performs one or several operations
- longer operations are broken up into "snippets" (`scripts/snippets`)
- See also the readmes in the `snippets` and `templates` directories

### Testing

- is a work in progress
- Run the `test` script
