# Movies App Deployment

This guide documents the process for deploying [this sample node
application](https://github.com/gocodeup/movies-application). In short, this
application is a node-powered API backend, combined with a frontend that is the
output of a webpack build process.

The document assumes your server command is `myserver`.

See also the [FAQs](faq.md), and the [usage guide](usage.md) for more in-depth
documentation.

* [Prerequisites](#prerequisites)
* [Make sure your application is ready](#make-sure-your-application-is-ready)
* [Create the site](#create-the-site)
* [Deploy your application](#deploy-your-application)
* [Debugging](#debugging)

## Prerequisites

1. A server setup with cods. Check out [the initial server setup guide
   here](initial-server-setup.md).
1. DNS Records for the domain you wish to deploy to configured properly. Check
   out [the DNS configuration guide here](dns-configuration.md).
1. A working movies application, that is, you should be able to run the
   application locally and have it be free of errors.

## Make sure your application is ready

In addition to running and being error free, we'll need to ensure 2 things:

1. We have a `npm run start` command

    Make sure you have a `"start"` entry in the `scripts` section of your
    `package.json`.

    For example, if you start your application by running the `server.js` script
    with node, your `package.json` would look like this:

    ```json
    {
        ...
        "scripts": {
            ...
            "start": "node server.js"
            ...
        }
        ...
    }
    ```

    You should now be able to run `npm run start` from the root of your project
    and have your application startup.

    Take note of the port number that your site is running on, we'll need this
    information later when we create a site.

1. Create a `cods.sh` file.

    This file will tell our server what needs to be done when the site is
    deployed. In our case, we'll want to install the dependencies, and build the
    static files.

    Create a file in your project root named `cods.sh`. It should have the
    following contents:

    ```sh
    echo 'Installing dependencies'
    npm install
    echo 'Building static assets'
    npm run build
    ```

    *We're assuming that `npm run build` puts together your static assets. This
    should be the case if you are deploying the movies application, but if you
    are deploying something else, you might need to use a different command
    here.*

## Create the site

```sh
myserver site create --domain example.com --node --port 3000
```

Replacing `example.com` with the domain name you want to deploy to.

You might also need to replace `3000` here if your application runs on a
different port number.

## Deploy your application

The command below:

```sh
myserver site info --domain example.com
```

Will output the location of your production git remote, including a
copy-pastable command you can use to add the git remote to your project. Go
ahead and do so:

```sh
git remote add production ...
```

Then make sure all your changes are added and committed, then push to
production:

```sh
git push origin main
```

When you push, you'll see the `cods.sh` script running, then you should see
your site live!

## Debugging

In general, debugging will fall into one of two categories, either something
goes wrong during the build process, that is, when you do a push, or something
goes wrong while the app is running, or starting up.

In general, try to reproduce any errors locally, so that your can solve them
locally, then push the fixes to production.

### Building

If anything goes wrong during the build process, you should see the output /
error messages after running a `git push` to production.

Occasionally, you will want to re-run the build process even though you don't
have any changes to push. In this case, you can run:

```bash
myserver site build --domain example.com
```

To trigger the same process that happens when you do a `git push`.

### While the app is running

Even if your application is built successfully, something might go wrong when
your application initially starts up, or at some point when it is running. You
can view the logs for your application by running:

```
myserver site logs --domain example.com
```

And you can watch the log file in realtime by running:

```
myserver site logs --domain example.com --follow
```

Press Ctrl-C to stop watching the log file.
