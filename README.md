# Setup Scripts

For setup and management of a remote server and virtual hosting with tomcat,
nginx, and mysql.

## Who this is for

Primarily, these scripts are intended to be used by [Codeup](http://codeup.com)
students going through the Java program. However, you might find this repo
useful if you have a Java web application you want to deploy quickly with
tomcat, or if you want to host several Java projects on the same server.

This project is probably **not** for you if:

- You need to deploy anything that is not a `war`
- You want to use a database that is not MySQL
- You want to use a webserver other than tomcat behind nginx

## Quick Start

Deploy a database backed blog application:

```bash
# 0. Create A VPS that you have ssh access to

# 1. Initialize a server
cods init my-awesome-server

# you now have a command named 'my-awesome-server' to interact with your server
# (command name is based on the name of the directory it is cloned in)

# 2. create a database and user for the application
my-awesome-server db create --name=blog_db --user=blog_user

# 3. setup your server to listen for requests for your domain (nginx + tomcat)
my-awesome-server site create --domain myblog.com

# 4. deploy the war (included here for the quickstart, but you should probably
#    look at git deployment)
my-awesome-server site deploy -d myblog.com -f /path/to/myblog-v0.0.1-SNAPSHOT.war
```

## Documentation

- [Usage Guide](docs/usage.md)
- [Step by Step Deployment Guide For a Spring Boot Application.](docs/deployment-guide.md)
- [Frequently Asked Questions](docs/faq.md)
- [How It Works](docs/how-it-works.md)

