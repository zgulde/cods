3.3.3 -- 20210301

- bugfix: rename cods config file to `cods-config`

3.3.2 -- 20210228

- bugfix: rename cods config file to `cods-config` (see 61bd079)

3.3.1 -- 20200818

- bugfix: don't error out when provisioning due to `cloud-init` package
- docs: update static site guides

3.3.0 -- 20200206

- bugfix: don't fail silently when creating a database that already exists
- enhancement: update python + php sample sites dependencies
- feature: add `cods list` subcommand

3.2.2 -- 20200205

- bugfix: Fix bug reading username in initial setup

3.2.0 -- 20190918

- Remove default-mysql-server install. This is a temporary workaround as we will
  install mysql v5.7 in production, and eventually this will be automated.

3.1.1 -- 20190823

- enhancement: be more safe when adding groups for new users

3.1.0 -- 20190823

- feature: more fine-grained control over `info` subcommands

3.0.3 -- 20190822

- bugfix: install curl before trying to use it

3.0.2 -- 20190822

- bugfix: provide default value for `root_user` in initial server setup

3.0.1 -- 20190822

- enhancement: upgrade flask sample site deps

3.0.0 -- 20190822

- **Note that this is a breaking change, and not 100% backwards compatible with
  any servers setup with cods v2.x**
- enhancement: Use debian 10 (buster)
- enhancement: stronger https config with nginx
- feature: add PHP site support (including laravel)
- feature: manage different java versions (8 and 11)
- feature: allow passwordless sudoing
- refactor: rename `install.sh` to `cods.sh`
- refactor: seperate user management into it's own subcommand
- refactor: rename `cods share` to `cods add`
- refactor: rename any user-facing command with ssl to https
- docs: add api doc page
- removed: the `devserver` subcommand
- tests: laravel + php site deployment tests
- tests: add subcommand shortcut to run all

2.2.3 -- 20190422

- docs: minor improvements/tweaks
- bugfix: update deps in python sample site
- bugfix: put https cert renewal into external script that runs in a cronjob

2.2.2 -- 20190201

- docs: more of them, and more modular
- bugfix: whitespace in CLI help message
- enhancement: more logging output in post-receive scripts

2.2.1 -- 20190127

- bugfix: [new users can now deploy to existing sites](https://github.com/zgulde/cods/issues/8)

2.2.0 -- 20190124

- feature: add python site type
- docs: document python site setup
- docs: improve usage guide
- docs: split off quick reference guide from the README, and expand on it
- tests: fix spring boot application

2.1.6 -- 20181108

- refactor: use `curl` instead of `wget` see 189ecaf for more detail

2.1.5 -- 20180911

- bugfix: apt was prompting us for input when initially provisioning the server,
  we'll make sure this is all automated now

2.1.4 -- 20180802

- refactor: move script location

2.1.3 -- 20180729

- I forgot to update the changelog, but still released the new version, so now
  we're up to 2.1.3

2.1.2 -- 20180723

- refactor: rename and move entrypoint scripts to bin/
- feature: add banner (try `cods/banner`)

2.1.1 -- 20180712

- bugix: fix port number issue when enabling https
- feature: better terminal output
- docs: document adding a user by github username (in the faqs)
- tests: add tests for static sites with a build process
- feature: use .cods file to automatically build static sites (not yet documented)

2.1.0 -- 20180708

- feature: better bash completion, all options are now completed, and
  completions aren't offered when it doesn't make sense to
- bugfix: static sites -- creation and post-receive hook
- docs: fix inaccuracies, more docs for java 1.8 + sb 1.x
- tests: add full deploy tests for a node site

2.0.1 -- 20180625

- bugfix: fix site restart in post-receive hook

2.0.0 -- 20180625

- added: Interactive help (`cods help`). Interactive walkthroughs for various
  deployment scenarios. Currently only contains help for deploying java projects
- added: The ability to deploy node applications
- added: Site type specifications to the site creation process. One of `--java`,
`--node`, or `--static`
- added: port number specification when creating a site. The port that the
  application will run on must now be specified
- added: `ports` subcommand to view ports being proxied to based on the nginx
  configuration files for each site
- added: The post-receive git hook for each site type will now only build and
  deploy when the master branch is pushed.
- removed: `log:tail` and `log:follow` subcommands commands. Logs are now
  accessible through the `site logs` subcommand.
- removed: Tomcat. All sites will need to be a self-contained web server. For
  our primary use case, deploying spring boot applications, we will not need to
  do too much different, and, in fact, we will actually have a little less
  configuration to do.
- removed: `site deploy` subcommand. Since we are no longer using tomcat and
  have a wide variety of site types, this no longer makes sense to keep.
- refactor: Individual sites are now managed through a systemd service
  unit. This includes logs for each application as well.
- refactor: most permissions. Each application will have a user and group
  created for it, and the relevant files/directories for each site will be used
  by that user and group.
- refactor: rename `.build_config` to `.cods`
- refactor: site creation. When creating a site, specifying a site type is now
  mandatory (one of `--java`, `--node`, or `--static`), and for java and node
  sites, a port number that the application will run on must be specified
- tests: refactored as necessary to reflect differences in permissions / site
  setup
- tests: added tests that fully deploy an application and ensure that the
  expected response is received from the application (`tests/deploy.sh`)
- docs: Updated to reflect all the changes outlined above
- docs: Added some documentation on deploying a node site

1.2.2 -- 20180504

- bugfix: fix typo in `adduser` help message

1.2.1 -- 20180503

- minor enhancement: add version information to `info` subcommand
- bugfix: quote variables that should be quoted

1.2.0 -- 20180503

- feature: enhance the `adduser` subcommand; add users to the server with a
  github username
- bugfix: Don't create the data directory for a command if the server setup fails

1.1.0 -- 20180426

- feature: add server command for enabling a swapfile

1.0.0 -- 20180423

- docs: more of them

There isn't really much new here, but the api is stable enough to commit to and
create a v1.

0.2.3 -- 20180227

- enhancement: add version information to `cods` command

0.2.2 -- 20180227

- bugfix: credentials are no longer recorded if user creation fails (26caf81)
- tests: make the testing setup easier
- tests: add tests for site removal

0.2.1 -- 20180222

- bugfix/enhancement: remove unneccesary sudo

0.2.0 --

- refactor to separate scripts for individual server management (user-defined)
  and server setup (`cods`)
