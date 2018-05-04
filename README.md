# Setup Scripts

For setup and management of a remote server and virtual hosting with tomcat,
nginx, and mysql.

## Who this is for

Primarily, these scripts are intended to be used by [Codeup](http://codeup.com)
students going through the Java program. However, you might find this repo
useful if you have a Java web application you want to deploy quickly with
tomcat, or if you want to host several Java projects on the same server.

This project is probably **not** for you if:

- You need to deploy anything that is not a `war` or a static site
- You want to use a database that is not MySQL
- You want to use a webserver other than tomcat behind nginx
- You want to use an operating system that is not Ubuntu on your server

## Quick Start

Deploy a database backed blog application:

```bash
# 0. Install
brew install zgulde/zgulde/cods

# 1. Create A VPS that you have ssh access to

# 2. Provision your server
cods init my-awesome-server
# 2a. Provide the server's ip address, and the server will be provisioned

# 2b. Go get a cup of coffee while everything is setup...

# You now have a command named 'my-awesome-server' to interact with your server

# 3. Create a database and user for the application
my-awesome-server db create --name=blog_db --user=blog_user

# 4. Setup your server to listen for requests for your domain (nginx + tomcat)
my-awesome-server site create --domain myblog.com

# 5. Deploy the war (included here for the quickstart, but you should probably
#    look at git deployment)
my-awesome-server site deploy -d myblog.com -f /path/to/myblog.war

# 6. (Optional) Turn on https for your site
my-awesome-server site enablessl -d myblog.com

# 7. (Optional) Deploy another site! You can host many sites on the same server
myserver site create --domain staging.myblog.com
myserver site create --domain myotherblog.org
```

## Documentation

- [Installation](docs/installation.md)
- [Usage Guide](docs/usage.md)
- [Step by Step Deployment Guide For a Spring Boot Application](docs/deployment-guide.md)
- [Frequently Asked Questions](docs/faq.md)
- [How It Works](docs/how-it-works.md)

