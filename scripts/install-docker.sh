#!/usr/bin/env bash

# Shell script to install docker and docker-compose
# author: Zach Gulde <zach.gulde@gmail.com>
#
# This script is more or less an automation of the guides found here:
#
# - https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04
# - https://www.digitalocean.com/community/tutorials/how-to-install-docker-compose-on-ubuntu-18-04
#
# Tested with ubuntu 16.04, 18.04 and debian buster.
#
# Usage
# -----
# 1. Copy this script to your server
# 2. Ensure the correct version of ubuntu is set in the variable below
# 3. Run the script with `bash install-docker.sh` and enter your sudo password
#    when prompted
#
# After the script finishes running, you'll need to log out and back in in order
# to run the `docker` command.

OS=$(lsb_release -is | tr '[A-Z]' '[a-z]')
OS_VERSION=$(lsb_release -cs)

install_docker() {
	sudo apt-get update -y
	sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

	curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo apt-key add -
	sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/$OS $OS_VERSION stable"

	sudo apt-get update -y
	sudo apt-get install -y docker-ce
}

add_user_to_docker_group() {
	sudo usermod -aG docker $USER
}

install_compose() {
	sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
	sudo chown root:docker /usr/local/bin/docker-compose
	sudo chmod g+rx /usr/local/bin/docker-compose
}

install_docker
install_compose
add_user_to_docker_group
