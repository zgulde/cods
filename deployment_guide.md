# Deployment Guide

This document is meant to supplement the [documentation included with the
deployment tool](https://github.com/gocodeup/tomcat-setup), and to be a mostly
complete guide to codeup students on deploying their spring boot applications.

See also the [FAQs](faq.md)

Note that if you are looking to add a site to an existing server, you should
skip the "First Time Server Setup" section.

## Overview

1. [First Time Server Setup](#first-time-server-setup)
1. [Get Your Application Ready For Deployment](#get-your-application-ready-for-deployment)
1. [Site Setup](#site-setup)

## First Time Server Setup

1. Sign up for digital ocean

1. Create a droplet on digitalocean.com

    Choose the $5/month, 1GB RAM droplet. Make sure to add your ssh key to the
    droplet! The command below will copy your public key to your clipboard.

    ```
    cat ~/.ssh/id_rsa.pub | pbcopy
    ```

1. Clone the deployment tool

    ```
    git clone git@github.com:gocodeup/tomcat-setup.git ~/myserver
    ```

1. Perform the initial setup

    ```
    cd ~/myserver
    ./server
    ```

    The script will prompt you for the server's IP address, so have it ready.

    Read the prompts that appear, and provide the necessary information.

After the last step above, a file located at `~/myserver/credentials.txt` will
be created. This file contains the admin password for your server, as well as
admin password for the mysql installation on the server.

You can access the credentials to your server by running:

```
myserver credentials
```

*If you are worried about storing the credentials in plain text, you can delete
this file and save your passwords in a password manager. However, if you lose
your passwords, they are _not_ recoverable!*

## Get Your Application Ready For Deployment

This tool is setup to host any web application that is packaged as a `war`.
Previously we have just been running the `main` method in our application, but
Spring boot will also allow us to package our application as a `war`.

1. Make sure your app runs locally!

    Before making any changes or deploying your application, make sure
    everything is working the way you expect it to locally.

    From the root of your project, run the following command:

    ```
    ./mvnw spring-boot:run
    ```

    This will start your application up from the command line, and more closely
    mimicks the environment your application will be running in in production.

    Press Ctrl + C to stop the server.

1. Tell our application to be bundled as a war

    We will need to make some changes to our application to allow it to be
    packaged as a `war`. These will be one-time operations, and we will still be
    able to run our application through the `main` method, like before.

    - Change the `<packaging>` in the `pom.xml` from `jar` to `war`

    Edit your class with the `main` method

    ```java
    import org.springframework.boot.SpringApplication;
    import org.springframework.boot.autoconfigure.SpringBootApplication;
    import org.springframework.boot.builder.SpringApplicationBuilder;
    import org.springframework.boot.web.support.SpringBootServletInitializer;

    @SpringBootApplication
    public class BlogApplication extends SpringBootServletInitializer {
        public static void main(String[] args) {
            SpringApplication.run(BlogApplication.class, args);
        }

        protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
            return application.sources(BlogApplication.class);
        }
    }
    ```

    - add the `extends` to the class definition
    - add the `configure` method

    *Note that you will need to replace `BlogApplication` with the name of your
    class with the main method.*

1. Make sure the `war` builds successfully

    Unless you've built out testing for your application, we will need to tell
    maven to skip running any tests before building the `war`.

    Add the following to your `pom.xml`

    ```
    <properties>
        ...
        <maven.test.skip>true</maven.test.skip>
    </properties>
    ```

    then, from the root of your project:

    ```
    ./mvnw package
    ```

    If this command produces any errors, read the error messages and fix them
    before proceeding.

1. Setup the `.build_config` file

    Create a file in the root of your project named `.build_config`. This file
    is what tells the server how to build our project. This file should have the
    following contents:

    ```
    BUILD_COMMAND='./mvnw package'
    WAR_FILE=target/blog-0.0.1-SNAPSHOT.war
    ```

    Your war file path could be different depending on how you named your
    project. To determine what the filepath should be, you should look for the
    `.war` file that is created in the `target` directory, or run this command
    from the root of your project:

    ```
    find target -name \*.war
    ```

    You can test that your `.build_config` file is setup correctly by running
    the following commands in your terminal from the root of your project:

    ```
    source .build_config
    eval "$BUILD_COMMAND"
    [[ -f $WAR_FILE ]] && echo 'Good to Go!' || echo 'WAR_FILE not found!'
    ```

    You should see no output from the first command, your project should build
    successfully after the second, and your should see "Good to Go!" output
    after the third.

    Once everything is ready to go, make sure to add and commit the
    `.build_config` file!

## Site Setup

1. Buy a domain name (we recommend namecheap), and point the DNS nameservers for
   that domain to digital ocean

    ```
    ns1.digitalocean.com
    ns2.digitalocean.com
    ns3.digitalocean.com
    ```

1. [Configure your domain's DNS settings with digital ocean.](https://cloud.digitalocean.com/networking)

    - Add an 'A' record that points to your droplet
    - optionally, add the 'www' subdomain, or all subdomains

1. Create a database for your site

    ```
    myserver db create --name blog_db --user blog_user
    ```

1. Setup your site

    This will prep tomcat and nginx to host your site. You will be prompted for
    your *server admin* password.

    ```
    myserver site create --domain example.com --spring-boot
    ```

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
    cd ~/IdeaProjects/springboot-blog
    myserver upload --file src/main/resources/application.properties --destination /srv/example.com/
    ```

    Then changing the relevant values

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
    git push production master
    ```
