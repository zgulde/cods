# Static Hugo Site Deployment Guide

This guide is written specifically for [hugo](https://gohugo.io), but can be
referenced for any type of static site build tool. We will walk through the
process of setting up a static site on your server that is (re-)built whenever
you `git push` to your `production` remote.

* [Prerequisites](#prerequisites)
* [Setup The Site](#setup-the-site)
* [Install Hugo](#install-hugo)
* [Setting Up The Server Site Build](#setting-up-the-server-site-build)
    * [The easy way with `.cods`](#the-easy-way-with-cods)
    * [More customization over the build process](#more-customization-over-the-build-process)
* [Push To Deploy](#push-to-deploy)

See also [the "Static Site Creation" section in the usage guide](usage.md#static-site-creation).

## Prerequisites

- A server setup with cods. [See the initial server setup guide
  here](initial-server-setup.md). We'll assume the command name is `myserver`.
- DNS Records for the domain you wish to deploy to configured properly. Check
  out [the DNS configuration guide here](dns-configuration.md).
- A working hugo application. That is, you should be able to build and view your
  static site locally.

## Setup The Site

1. Run the command to create the site

    ```
    myserver site create --static --domain example.com
    ```

2. Add the git remote to your project

    ```
    git remote add production ...
    ```

## Install Hugo

Even though you might have hugo (or whatever other build tool you are using)
installed on your laptop, you'll also need to install hugo on your server.

```
myserver run sudo apt-get install hugo
```

## Setting Up The Server Site Build

Next we'll setup some configuration so that whenever you push to `production`,
your build process is triggered and the site is deployed.

### The easy way with `.cods`

If your build process consists of running a single command, and the output of
your build is a single directory that contains the contents of your site, you
can setup a `.cods` file that explains this to the server.

Create a file named `.cods` at the root of your project with the following
contents:

```
BUILD_COMMAND='hugo'
OUTPUT_DIR=public
```

### More customization over the build process

If you need to do something more custom, that is, you need to run more commands
than what is described above, you can create a file named `cods.sh`, and
whatever commands are in this file will be run whenever you push to production.

For example, if you are using a theme with hugo and the theme is a git
submodule, you first need to make sure the submodule is ready to go before you
can build the site contents.

Create a file named `cods.sh` at the root of your project with the following
contents (customize to suit your needs of course):

```
set -u

# clone the theme
git submodule init
git submodule update

# build the site
hugo

# do whatever else you need to do
# i.e. run any other commands

rm -f $public_dir/*
mv public/* $PUBLIC_DIR
```

Here we're assuming `hugo` builds your site, and, after running any other custom
commands, the result is a `public` directory that contains your site's build
HTML, CSS, and JS.

The last two lines above are what actually deploy the site. $PUBLIC_DIR is the
location of the static files that are in production, and the last two lines
remove whatever is currently there, and replace it with the contents of the
`public` directory you just built.

## Push To Deploy

Now that everything is in place, simply push to production to deploy your site:

```
git push production main
```
