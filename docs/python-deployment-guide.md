# Python Deployment Guide

* [Prerequisites](#prerequisites)
* [Application Prep](#application-prep)
    * [Make Sure the Application is Ready](#make-sure-the-application-is-ready)
    * [Server Startup Script](#server-startup-script)
    * [Deployment Script](#deployment-script)
* [Create The Site](#create-the-site)
* [Deploy Your Code](#deploy-your-code)
    * [Monitoring Your Application](#monitoring-your-application)

## Prerequisites

- A server setup with cods. [See the initial server setup guide
  here](initial-server-setup.md). We'll assume the command name is `myserver`.
- DNS Records for the domain you wish to deploy to configured properly. Check
  out [the DNS configuration guide here](dns-configuration.md).
- A working python + flask application. That is, you should be able to run the
  app locally without any errors.

## Application Prep

In order to deploy a python application with this tool, you need to provide a
shell script, `start_server.sh` that is executable and that starts up your web
server.

We'll also create a script that runs whenever our code is deployed that will
re-create our virtual environment.

### Make Sure the Application is Ready

1. Delete and re-create the virtual environment.

    ```
    rm -rf env
    python -m venv env
    source env/bin/activate
    python -m pip install -r requirements.txt
    ```

1. Run your application and ensure that everything is how you expect it to be.

    That is, make sure that your application still works the way you would
    expect it to after re-creating the virtual environment and installing
    dependencies.

1. Make sure your working directory is clean (i.e. all of your work has been
   added and committed to git).

### Server Startup Script

We need to create a file named `start_server.sh`. This script should start up
your application in production mode.

Here's an example of how we might setup this script with an existing flask
application that you'd previously been running with the `flask run` command. (If
you already setup this script, you can skip the rest of this section.)

1. Install [`waitress`](https://docs.pylonsproject.org/projects/waitress/en/latest/index.html).

    Waitress is a python library that can serve our flask application in a
    production environment.

    ```
    source env/bin/activate
    python -m pip install waitress
    python -m pip freeze > requirements.txt
    ```

1. Add code to use `waitress` in your application

    Within the file file that defines your flask `app`, add the following:

    ```python
    if __name__ == '__main__':
        import waitress
        waitress.serve(app, port=5005)
    ```

    The port number here is arbitrary, but needs to be unique to your server,
    that is, if you have multiple python application deployed on your server,
    they can't use the same port number.

    After adding the above code, you can start your application and serve it
    with waitress by running the script above. Assuming your script is named
    `server.py`, you would do so with the following command:

    ```
    python server.py
    ```

1. Create the startup script

    This script is basically a sequence of shell commands that you would use to
    start up the server. We'll also add a couple of `echo` statements for
    informative output.

    Take a look at the code snippet below:

    ```
    #!/usr/bin/env bash

    set -e # cause the script to exit on any errors

    echo '[start_server.sh] Activating Virtual Environment'
    source env/bin/activate
    echo '[start_server.sh] Starting The Server'
    python server.py
    ```

    Copy the code above into a file named `start_server.sh`. If your virtual
    environment is not in a directory named `env`, or your application
    entrypoint is not `server.py` you'll need to tweak the code above,
    otherwise, you shouldn't need to make any changes.

1. Make the startup script executable

    ```
    chmod +x start_server.sh
    ```

1. Add and commit the script.

### Deployment Script

We will also create a file that runs whenever a new version of our code is
deployed.

Copy the following into a file named `cods.sh`:

```
# Script used for deployment with cods (https://github.com/zgulde/cods)
set -e

cd $SITE_DIR

echo "[cods.sh] (re-)creating the venv"
rm -rf env
python3 -m venv env
echo '[cods.sh] Activating venv and installing dependencies'
source env/bin/activate
python3 -m pip install -r requirements.txt
```

By adding the script above, we will instruct our server to re-create our
application's virtual environment and re-install dependencies whenever we deploy
a new version.

## Create The Site

1. Make note of the port number that your application runs on

    The port number is arbitrary, but needs to be unique within your server,
    that is, if you have multiple python application deployed on your server,
    they can't use the same port number.

1. Run the command below to setup the site:

    ```
    myserver site create --python --port 5005 --domain example.com
    ```

    Replacing `5005` with your application's port number, and `example.com` with
    the name of the domain you are setting up (subdomains are okay too, so long
    as the DNS records are setup properly).

1. (Optionally) enable https for your site

    ```
    myserver site enablehttps --domain example.com
    ```

    Again, replacing `example.com` with your domain.

## Deploy Your Code

1. A a deployment git remote to your project

    ```
    myserver site info --domain example.com
    ```

    Again replacing `example.com` with your domain.

    You'll see a command that you can copy and paste to add `production` remote.
    Go ahead and do this.

1. Make sure all of your work is added and committed

1. Push to `production` deploy your code

    ```
    git push production main
    ```

    You should see the code from your `cods.sh` file run whenever you push to
    `production`.

### Monitoring Your Application

To view the output from your application (i.e. to see `print` statements or any
errors that are produced), you'll need to view the logs from the server. You can
do so in one of two ways:

1. View the entire log file

    ```
    myserver site logs --domain example.com
    ```

    This command will dump the contents of the logfile out to your terminal.

1. Watch the logfile in real-time

    ```
    myserver site logs --domain example.com --follow
    ```

    Press Ctrl-C to stop watching the log file.
