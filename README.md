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

## Interactive Help

```
cods help
```

## Documentation

- [Quick Reference](docs/quick-reference.md)
- [Installation](docs/installation.md)
- [Initial Server Setup](docs/initial-server-setup.md)
- [Domain DNS Configuration](docs/dns-configuration.md)
- [Usage Guide](docs/usage.md)
- [Frequently Asked Questions](docs/faq.md)
- [Step by Step Deployment Guide For a Spring Boot Application](docs/spring-boot-deployment-guide.md)
- [Step by Step Deployment Guide For a Node + Webpack Application](docs/node-movies-deployment-guide.md)
- [How It Works](docs/how-it-works.md)

