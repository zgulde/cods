# Deployment

This document is meant to supplement the [documentation included with the
deployment tool](https://github.com/gocodeup/tomcat-setup), and to be a mostly
complete guide to codeup students on deploying their spring boot applications.

## Build A War From your application

1. Make sure your app runs locally!

1. Tell our application to be bundled as a war

    - Change the `<packaging>` in the `pom.xml` from `jar` to `war`

    Edit your class with the `main` method

    ```java
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

1. Change any values that need to be changed for production

    - database credentials in the `application.properties` file

1. Build the war

    Unless you've built out testing for your application, we will need to tell
    maven to skip running any tests.

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

Once the `war` is built, you'll need to change the values in the
`application.properties` back in order to continue local development.

## Server + Domain Name

1. Buy a domain name (we recoment namecheap), and point the DNS nameservers to
   digital ocean

    ```
    ns1.digitalocean.com
    ns2.digitalocean.com
    ns3.digitalocean.com
    ```

1. Sign up for digital ocean, use the coupon code we give you for $25 credit

1. Create a droplet on digitalocean.com

    Choose the $10/month, 1GB RAM droplet

    add your ssh key to the droplet

    ```
    pbcopy < ~/.ssh/id_rsa.pub
    ```

1. [Configure your domain's DNS settings with digital ocean.](https://cloud.digitalocean.com/networking)

    - Add an 'A' record that points to your droplet
    - optionally, add the 'www' subdomain

1. Clone the deployment tool

    ```
    git clone git@github.com:gocodeup/tomcat-setup.git ~/my-server
    ```

1. Provision the server with the setup script

    Have the server's ip address ready, and be ready to choose 2 passwords, one
    for the server administrator, and one for the database administrator.

    ```
    cd ~/my-server
    ./setup
    ```

1. Setup your site

    This will prep tomcat and nginx to host your site. You will be prompted for
    your *server admin* password.

    ```
    ./site create example.com
    ```

    If the DNS records are improperly configured, the script will warn you, you
    can go ahead and continue, you just won't be able to see your site unless
    you add an entry to your `/etc/hosts` file like the following:

    ```
    111.111.111.111 example.com
    ```

1. Create a database for your site

    ```
    ./db create blog_db blog_user
    ```

    You will be prompted to choose a password for the new user, then we will
    require your *database admin* password to setup the user.

    The user and password you create here are what you should eventually put in
    your `application.properties` file.

1. Deploy a war

    ```
    ./site deploy example.com ~/IdeaProjects/myblog/target/blog-1.0-SNAPSHOT.war
    ```

     ./server tomcatlog

    (optionally) enable ssl

    Note that your DNS must be configured in order to do this

     ./site enablessl example.com
     # setup automatic renewal of certificates
     ./server enableautorenew

## Troubleshooting Deployment Problems

- Check the logs!

    ```
    ./server tomcatlog
    ```

    will dump out the tomcat log file located on your server at
    `/opt/tomcat/logs/catalina.out`

    note you will need your server admin password for this operation

- Can you reproduce it locally?

## Deploying Changes To An Existing Application

1. Change any necessary values in the `application.properties` file.

1. Rebuild the `war`

    ```
    cd ~/IdeaProjects/my-project
    ./mvnw package
    ```

1. Deploy the new `war`

    ```
    cd ~/my-server
    ./site deploy example.com ~/IdeaProjects/my-project/target/project-0.0.1-SNAPSHOT.war
    ```

## Creating a new site on a server that is already setup

1. Do any necessary domain name and DNS record setup

1. create the site

    ```
    ./site create example.com
    ```

1. create a database for the application

    ```
    ./db create my_project my_user
    ```

1. deploy the `war`

    ```
    ./site deploy example.com ~/IdeaProjects/my-project/target/project-0.0.1-SNAPSHOT.war
    ```

## HTTPS

See the main readme for instructions on enabling https. After doing that, you
can run the following command to setup auto-renewal of any ssl certificates:

```
./server autorenew
```
