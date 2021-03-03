# Deployment Guide

This document is meant to supplement the [usage guide](usage.md), and to be a
mostly complete guide to codeup students on deploying their spring boot
applications.

See also the [FAQs](faq.md), and the [usage guide](usage.md) for more in-depth
documentation.

* [Prerequisites](#prerequisites)
* [Overview](#overview)
* [Get Your Application Ready For Deployment](#get-your-application-ready-for-deployment)
* [Site Setup](#site-setup)
* [Debugging](#debugging)

## Prerequisites

1. A server setup with cods. [See the initial server setup guide
   here](initial-server-setup.md)
1. DNS Records for the domain you wish to deploy to configured properly. Check
   out [the DNS configuration guide here](dns-configuration.md)
1. A working spring boot application. That is, you should be able to run the app
   locally without any errors.

## Overview

1. [Get Your Application Ready For Deployment](#get-your-application-ready-for-deployment)
1. [Site Setup](#site-setup)

This document assumes your server command is `myserver`.

## Get Your Application Ready For Deployment

This tool is setup to host any web application that is packaged as a `jar` that
is "self-contained", meaning that it does not depend on an external application
server like tomcat. Previously we have just been running the `main` method in
our application, but Spring boot will also allow us to package our application
as a `jar` and run it.

0. Make sure you have committed all changes and your application is free from
   errors.

1. If your application is using spring boot v1.x and you have multiple versions
   of Java installed on your machine, [see the FAQ
   here](faq.md#do-i-need-to-do-anything-differently-if-i-have-multiple-java-installations)

1. Skip Tests

    Unless you've built out testing for your application, you'll want to add the
    `skipTests` element below to your `pom.xml`:

    ```xml
    ...
	<properties>
        ...
        <skipTests>true</skipTests>
        ...
	</properties>
    ...
    ```

1. Package the application as a jar

    From the root of your project, run the following command:

    ```
    ./mvnw package
    ```

    This will package your application and turn it into one big `.jar` file,
    which will be output to the `target` directory.

    If any error occur after running this command, read the error messages, fix
    them, and try running it again.

    You can find the path to your output jar file by running:

    ```
    find target -name \*.jar
    ```

    Take note of this filepath, as we will reference it again.

1. Run the application from the command line

    To more closely mimick the way in which your application will run in
    production, we'll run it from the command line and ensure everything is
    working the right way.

    The command below will run the jar file that was produced in the last step:

    ```
    java -jar YOUR_JAR_FILE
    ```

    Replacing `YOUR_JAR_FILE` with the filepath you found in the previous step.
    For example, the command might look like this:

    ```
    java -jar target/codeup-blog-0.0.1-SNAPSHOT.jar
    ```

    This will start up the web server in a similar way that running the main
    method from your IDE does.

    Open up the application in your browser and ensure that everything is still
    running the way you want it to. Once you are satisfied, press Ctrl-C in your
    terminal to stop the server.

1. Setup the `.cods` file

    Create a file in the root of your project named `.cods`. This file
    is what tells the server how to build our project. This file should have the
    following contents:

    ```
    BUILD_COMMAND='./mvnw package'
    JAR_FILE=target/blog-0.0.1-SNAPSHOT.jar
    ```

    Your jar file path could be different depending on how you named your
    project. Again here you should use the filepath you found in the previous
    step.

    You can test that your `.cods` file is setup correctly by running the
    following commands in your terminal from the root of your project:

    ```
    source .cods
    eval "$BUILD_COMMAND"
    [[ -f $JAR_FILE ]] && echo 'Good to Go!' || echo 'JAR_FILE not found!'
    ```

    You should see no output from the first command, your project should build
    successfully after the second, and your should see "Good to Go!" output
    after the third.

    Once everything is ready to go, make sure to add and commit the
    `.cods` file!

## Site Setup

1. Create a database for your site

    ```
    myserver db create --name blog_db --user blog_user
    ```

1. Setup your site

    This will prep the server to host your site. You will be prompted for your
    *server admin* password.

    ```
    myserver site create --domain example.com --java --spring-boot --port 8080
    ```

    We'll choose 8080 for the port number here, but if you deploy more than one
    site, you will need to choose a different port number for each one (e.g.
    8000 or 8888). You can run `myserver ports` to view the ports that are being
    used on your server.

    If the DNS records are improperly configured, the script will warn you, you
    can go ahead and continue, you just won't be able to see your site until the
    records are properly configured.

    We'll pass the `--spring-boot` flag to automatically take care of some
    common configuration for a spring boot application.

1. Create the production `application.properties` file

    Since `application.properties` file is ignored by git (as it should be), we
    will need to manually create this file on the server. The database name and
    user that go in this file should match up with the values you used when
    running the `db create` command.

    You can find the password for your database user by running:

    ```
    myserver credentials
    ```

    It's usually easiest to start by copying your local `application.properties`
    to the server

    ```
    # run this from the root of your spring boot project
    myserver upload --file src/main/resources/application.properties --destination /srv/example.com/application.properties
    ```

    Then changing the relevant values. That is, change the database user and
    password to the ones you created in the last step.

    ```
    myserver run nano /srv/example.com/application.properties
    ```

    *Make sure to replace `example.com` with the name of your actual site in the
    two commands above.*

    To save and exit nano:

    1. Ctrl-x
    1. Type `y`
    1. Press Enter

1. Add the deployment remote to your project and push to deploy the site

    You can find your deployment remote (and a copy-pasteable command to add it
    to your project) by running:

    ```
    myserver site info --domain=example.com
    ```

    Replacing `example.com` with the name of the site you just setup.

    Copy and paste the command to add the `production` remote, and push up to
    production

    ```
    git push production main
    ```

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
