# Setup Scripts

For setup and management of a remote server and virtual hosting with nginx,
which serves mostly as a reverse proxy to application servers that (optionally)
talk to a mysql database.

## Who this is for

Primarily, these scripts are intended to be used by [Codeup](http://codeup.com)
students going through the Java program. However, you might find this repo
useful if you have a Java web application with an embedded server you want to
deploy quickly with, or if you want to host several projects on the same server.

This project is probably **not** for you if:

- You want to use a database that is not MySQL
- You want to use a webserver other than nginx
- You don't want to put nginx in front of your application
- You want to use an operating system that is not Ubuntu on your server

## Quick Start

Deploying a database backed blog application:

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
    git push production master
    ```

    And you site will build and be live!

1. (Optional) Setup https for your site (uses letsencrypt under the hood)

    ```
    my-awesome-server site enablessl -d myblog.com
    ```

1. (Optional) Deploy another site! You can host many sites on the same server

    ```
    my-awesome-server site create --node --domain api.myblog.com
    my-awesome-server site create --static --domain myotherblog.org --enable-ssl
    ```

## Interactive Help

```
cods help
```

## Documentation

- [Installation](docs/installation.md)
- [Usage Guide](docs/usage.md)
- [Step by Step Deployment Guide For a Spring Boot Application](docs/deployment-guide.md)
- [Frequently Asked Questions](docs/faq.md)
- [How It Works](docs/how-it-works.md)

