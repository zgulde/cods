# Quick Reference

* [Initial Server Setup](#initial-server-setup)
* [Java + Spring Boot Site](#java--spring-boot-site)
* [Static Site](#static-site)
* [Node Site](#node-site)
* [Python Site](#python-site)
* [Enable Https](#enable-https)

## Initial Server Setup

0. Setup

    ```
    brew install zgulde/zgulde/cods
    ```

    And Create a VPS you have root ssh access to

1. Provision the server

    ```
    cods init my-awesome-server
    ```

    Provide the server's IP address, answer a couple questions, then grab a cup
    of tea while the server is setup.

    You'll now have a command named `my-awesome-server` to interact with your
    server.

## Java + Spring Boot Site

Deploying a java spring-boot database backed blog application:

1. Create a database for the site

    ```
    my-awesome-server db create --name blog_db --user blog_user
    ```

    A random password will be generated for you

1. Setup the site

    ```
    my-awesome-server site create --domain myblog.com --java --spring-boot --port 8080
    # define db secrets...
    my-awesome-server run vim /srv/myblog.com/application.properties
    ```

1. Create a file that defines how to build your site

    ```
    cat > .cods <<.
    BUILD_COMMAND='./mvnw package'
    JAR_FILE=$(find target -name \*.jar)
    .
    ```

1. Add a git remote and push

    ```
    my-awesome-server site info -d myblog.com
    ```

    Will give you a copy-pastable command to add a `production` remote. Then:

    ```
    git push production main
    ```

    And you site will build and be live!

## Static Site

1. Create the site

    ```bash
    my-awesome-server site create --domain myblog.com --static
    ```

1. Add a git remote and push

    ```
    my-awesome-server site info -d myblog.com
    ```

    Will give you a copy-pastable command to add a `production` remote. Then:

    ```
    git push production main
    ```

    And the contents of your repo will be live on your domain!

## Node Site

1. Create the site

    ```bash
    my-awesome-server site create --domain myblog.com --node --port 9000
    ```

1. Make sure your application is ready

    `npm run start` should start your server on the port you specified in the
    last step

1. Add a git remote and push

    ```
    my-awesome-server site info -d myblog.com
    ```

    Will give you a copy-pastable command to add a `production` remote. Then:

    ```
    git push production main
    ```

    And the contents of your repo will be live on your domain!

## Python Site

1. Create the site

    ```bash
    my-awesome-server site create --domain myblog.com --python --port 5000
    ```

1. Create a startup script

    ```bash
    cat > start_server.sh <<.
    #!/usr/bin/env bash

    source env/bin/activate
    python server.py
    .
    chmod +x start_server.sh

    git add start_server.sh
    git commit -m 'Add script for managing server startup'
    ```

    Assuming you are using a virtual environment

1. Add a git remote and push

    ```
    my-awesome-server site info -d myblog.com
    ```

    Will give you a copy-pastable command to add a `production` remote. Then:

    ```
    git push production main
    ```

    And the contents of your repo will be live on your domain!

## Enable Https

```
my-awesome-server site enablehttps -d myblog.com
```
