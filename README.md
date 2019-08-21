# Setup Scripts

For setup and management of a single remote server and virtual hosting with
nginx, which serves mostly as a reverse proxy to application servers that
(optionally) talk to a mysql database.

## Who this is for

If you want to quickly deploy your application on the same server that hosts
your database and not worry about the infastructure details that entails, this
project can help you out.

Primarily, these scripts are intended to be used by [Codeup](http://codeup.com)
students going through the Java program. You might also find this project useful
if you have a Java, Python, PHP, or Node web application you want to deploy
quickly, or if you want to host several hobby projects on the same server.

This project is probably **not** for you if:

- You want to use a database that is not MySQL
- You don't want to put nginx in front of your application
- You want to use an operating system that is not Ubuntu on your server

## Documentation

- [Quick Reference](docs/quick-reference.md)
- [Installation](docs/installation.md)
- [Initial Server Setup](docs/initial-server-setup.md)
- [Domain DNS Configuration](docs/dns-configuration.md)
- [Usage Guide](docs/usage.md)
- [API Docs](docs/api.md)
- [Frequently Asked Questions](docs/faq.md)
- [Step by Step Deployment Guide For a Spring Boot Application](docs/spring-boot-deployment-guide.md)
- [Step by Step Deployment Guide For a Node + Webpack Frontend Application](docs/node-movies-deployment-guide.md)
- [Step by Step Deployment Guide For a Python Flask Application](docs/python-deployment-guide.md)
- [Getting More Help](SUPPORT.md)
