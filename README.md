# Setup Scripts

For setup and management of a remote server with tomcat and nginx.

these scripts will allow you to setup tomcat behind nginx and quickly deploy
wars to your tomcat installation, and easily create and manage databases on your
server.

## prereqs

1. a ubuntu 16.04 server with your ssh key on it

## setup

1. clone this repo
1. run the setup script

## Notes

At any time you can press Control-C to exit.

When you are prompted to enter a password, you will not see any output on the
screen. This is normal.

## Commands

`./setup`

    Setup your server for the first time

`./server`

    Interact with your server

`./site`

    Command for manipulating sites your server is setup to host

