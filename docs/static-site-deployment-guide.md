# Static Site Deployment Guide

This guide will walk you through creating and deploying a static site with
`cods`. A prerequisite for this guide is a server command setup with cods, we
will assume the command is named `myserver`. This guide is written for a "plain"
static site, that is, a site where the contents of the repository should just be
served to the public and there is no backend or build process.

See also [the "Static Site Creation" section in the usage
guide](usage.md#static-site-creation) or the other deployment guides for more
complicated site setups.

## Prerequisites

- A server setup with cods. [See the initial server setup guide
  here](initial-server-setup.md). We'll assume the command name is `myserver`.
- DNS Records for the domain you wish to deploy to configured properly. Check
  out [the DNS configuration guide here](dns-configuration.md).

## Create The Site

This section will walk you through creating a (**_very_**) basic static site and
initializing a git repository. Skip this section if you have an existing project
you want to deploy.

1. Create an `index.html` file.

    You site could be more complex, but let's start by creating an `index.html`
    file. This will be the home page for your domain.

    ```html
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="UTF-8"/>
        <title>My Website</title>
      </head>
      <body>
        <h1>Hello From Cods!</h1>
      </body>
    </html>
    ```

1. Initialize the git repository

    ```
    git init
    git add index.html
    git commit -m 'First Commit'
    ```

1. (Optionally) push your repository up to GitHub.

    Go to [github.com/new](https://github.com/new) and create a repo, then add
    the remote and push.

    ```
    git remote add origin ...
    git push origin main
    ```

## Create The Site

Next we will setup your server to host the site. Run the command below:

```
myserver site create --domain example.com --static
```

replacing `example.com` with your domain name (or a subdomain).

## Push To Deploy

After the site creation command above finishes, you should see some output that
gives you a copy-pastable `git` command to add a `production` remote to your
repository.

Alternatively, you can find this command by running

```
myserver info --domain example.com
```

Either way after running the command to add the production remote, go ahead and
push:

```
git push production main
```

After pushing, you should see your site live!
