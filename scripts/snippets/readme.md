# snippets

This directory contains various configuration snippets. These snippets are all
intended to be executed on the remote machine. Each snippet also expects certain
variables to be set, which will be indicated in a comment at the top of the
script. We'll use `set -u` to cause the snippets to fail if any of the
referenced variables are unset. The `server` script (or a subcommand) will
invoke these snippets and set the proper variables like so:

```
ssh $user@$ip "
foo=$bar
$(< some-snippet.sh)
"
```
