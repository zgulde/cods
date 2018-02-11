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

Deploy a blog application and create a database for it:

```bash
# 0. Create A VPS that you have ssh access to

# 1. clone this repo
git clone https://github.com/zgulde/tomcat-setup.git ~/my-awesome-server
cd ~/my-awesome-server

# 2. initial server setup
./server

# 3. create a database and user for the application
my-awesome-server db create --name blog_db --user blog_user

# 4. setup your server to listen for requests for your domain
my-awesome-server site create --domain myblog.com

# 5. deploy the war (included here for the quickstart, but your should probably
#    setup git deployment)
my-awesome-server site deploy -d myblog.com -f /path/to/myblog-v0.0.1-SNAPSHOT.war
```

## Documentation

- [Usage Guide](docs/usage.md)
- [Step by Step Deployment Guide For a Spring Boot Application.](docs/deployment_guide.md)
- [Frequently Asked Questions](docs/faq.md)

