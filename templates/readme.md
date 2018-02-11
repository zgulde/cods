# Templates

This directory holds various configuration file templates.

When the server is first setup, all the templates here are transferred to the
server (`/srv/.templates`), so if you want to make any changes to these
templates, you will need to get the templates on the server back in sync.

you might run something like:

```
myserver run rm -vr /srv/.templates
myserver upload -f templates -d /srv/.templates
```

to copy any changes you've made locally to the server

Note that this will change any *future* configuration files that are created,
but existing ones will not be changed.
