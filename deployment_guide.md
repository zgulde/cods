# Deployment

This document is meant to supplement the [documentation included with the
deployment tool](https://github.com/gocodeup/tomcat-setup), and to be a mostly
complete guide to codeup students on deploying their spring boot applications.

## Overview

1. Change the application to be buildable as a `war`.
1. Setup + Provision the server
1. Setup a database and site
1. Login to configure git deploment
1. Add the git remote to your project and push

## Build A War From your application

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

    *Note: instead of modifying the `pom.xml`, you could also pass the
    `-DskipTests` flag to the maven package command.*

1. Setup the `.build_config` file

    Create a file in the root of your project named `.build_config`. This file
    is what tells the server how to build our project. This file should have the
    following contents:

        BUILD_COMMAND='./mvnw package'
        WAR_FILE=target/blog-0.0.1-SNAPSHOT.war

    *Your war file path could be different depending on how your project is
    setup, make sure the name of the war file matches up with what you defined
    in your `pom.xml`.*

    Make sure to add and commit the `.build_config` file!

## Server + Domain Name

1. Buy a domain name (we recommend namecheap), and point the DNS nameservers for
   that domain to digital ocean

    ```
    ns1.digitalocean.com
    ns2.digitalocean.com
    ns3.digitalocean.com
    ```

1. Sign up for digital ocean

1. Create a droplet on digitalocean.com

    Choose the $10/month, 1GB RAM droplet. *Note: choosing a smaller size
    droplet here can lead to out-of-memory crashes!*

    add your ssh key to the droplet

    ```
    cat ~/.ssh/id_rsa.pub | pbcopy
    ```

1. [Configure your domain's DNS settings with digital ocean.](https://cloud.digitalocean.com/networking)

    - Add an 'A' record that points to your droplet
    - optionally, add the 'www' subdomain

1. Clone the deployment tool

    ```
    git clone git@github.com:gocodeup/tomcat-setup.git ~/my-server
    ```

1. Provision the server with the setup script

    The script will prompt you for the server's IP address, so have it ready.

    ```
    cd ~/my-server
    ./server
    ``` 

1. Create a database for your site

    ```
    ./server db create blog_db blog_user
    ```

    You will be prompted to choose a password for the new user, then we will
    require your *database admin* password to setup the user.

    The user and password you create here are what you should eventually put in
    your production `application.properties` file.

1. Setup your site

    This will prep tomcat and nginx to host your site. You will be prompted for
    your *server admin* password.

    ```
    ./server site create example.com
    ```

    If the DNS records are improperly configured, the script will warn you, you
    can go ahead and continue, you just won't be able to see your site unless
    you add an entry to your `/etc/hosts` file like the following:

    ```
    111.111.111.111 example.com
    ```

    The output of this command will contain instructions for adding a git remote
    for deploment. Take note of this command, we will be using it later on.

1. Log in to the server to finalize deployment setup

    Login to the server.

        ./server login

    Create the production `application.properties` file.

    This file should be located in `~/example.com/application.properties` on
    your server, and should contain your production credentials.

    Next, uncomment the two lines in `~/example.com/.config` that reference the
    `application.properties` file.

    You can now log out of the server.

1. Deploy the site

    Add the git remote (from the site setup command) to your project, and push
    to your new remote.

1. (optionally) enable ssl

## Troubleshooting Deployment Problems

- Check the logs!

    ```
    ./server tomcatlog
    ```

    will dump out the tomcat log file located on your server at
    `/opt/tomcat/logs/catalina.out`

    note you will need your server admin password for this operation

- Can you reproduce it locally?

    Don't try to troubleshoot deployment problems in production, rather you
    should try and reproduce the problem locally, fix it, and the deploy the
    fixed version of your application.

- Did you:

    - Change your class with the `main` method?
    - Change the `packaging` in your `pom.xml`?
    - Add the `.build_config` file?
    - Setup the site on the server?
    - Setup a database on the server?
    - Setup the production `application.properties` file?
    - Setup the `.config` file on your server?
    - Push your changes?

## Deploying Changes To An Existing Application

To make changes to an existing site, simply commit the changes and push to your
deployment remote.

## Creating a new site on a server that is already setup

1. Do any necessary domain name and DNS record setup

1. create the site

    ```
    ./server site create example.com
    ```

1. create a database for the application

    ```
    ./server db create my_project my_user
    ```

1. Login to the server to setup the production `application.properties` file and
   edit the `.config` file

1. Make sure your project is packagable as a `war` and has a `.build_config`
   file

1. Add the git remote and push

## HTTPS

See the main readme for instructions on enabling https. After doing that, you
can run the following command to setup auto-renewal of any ssl certificates:

```
./server autorenew
```

## Manual Deployment

In addition to deploying with git, you can manually deploy a `war` to your site
with the command below:

    # from ~/my-server
    ./server site deploy example.com ~/IdeaProjects/myblog/target/blog-1.0-SNAPSHOT.war
