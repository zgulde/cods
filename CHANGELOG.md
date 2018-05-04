1.2.2

- bugfix: fix typo in `adduser` help message

1.2.1

- minor enhancement: add version information to `info` subcommand
- bugfix: quote variables that should be quoted

1.2.0

- feature: enhance the `adduser` subcommand; add users to the server with a
  github username
- bugfix: Don't create the data directory for a command if the server setup fails

1.1.0

- feature: add server command for enabling a swapfile

1.0.0

- docs: more of them

There isn't really much new here, but the api is stable enough to commit to and
create a v1.

0.2.3

- enhancement: add version information to `cods` command

0.2.2

- bugfix: credentials are no longer recorded if user creation fails (26caf81)
- tests: make the testing setup easier
- tests: add tests for site removal

0.2.1

- bugfix/enhancement: remove unneccesary sudo

0.2.0

- refactor to separate scripts for individual server management (user-defined)
  and server setup (`cods`)
