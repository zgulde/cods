# Initial Server Setup

This setup guide will provide instructions for digital ocean, but, in theory,
this tool should be able to be used with any VPS provider that gives you root
ssh access to a server.

1. Sign up for digital ocean

1. Create a droplet on digitalocean.com

    A "droplet" is what digital ocean calls it's virtual servers.

    Choose Debian 10 as the operating system, and the $5/month, 1GB RAM option
    for the size of the server.

    Make sure to add your ssh key to the droplet! The command below will copy
    your public key to your clipboard. Be sure to run this command on your development machine.

    ```
    cat ~/.ssh/id_rsa.pub | pbcopy
    ```

1. Install the deployment tool to your Mac OS.

    ```
    brew install zgulde/zgulde/cods
    ```

    See the [installation guide](installation.md) if you are not on MacOS.

1. Perform the initial setup. Run this command on your development machine.

    ```
    cods init myserver
    ```

    The `myserver` part of the command above specifies the name of the command
    that will be created that you will use to interact with your server. You can
    choose something different here (e.g. `my-awesome-server`), but this guide
    (and the other documentation) will assume you have chosen `myserver`.

    The script will prompt you for the server's IP address, so have it ready.

    Read the prompts that appear, and provide the necessary information.

After the last step above, you will be able to run the command

```
myserver
```

to interact with your server. In addition, a file located at
`~/.config/cods/myserver/credentials.txt` will be created. This file contains
the admin password for your server, as well as admin password for the mysql
installation on the server.

You can access the credentials to your server by running:

```
myserver credentials
```

*If you are worried about storing the credentials in plain text, you can delete
this file and save your passwords in a password manager. However, if you lose
your passwords, they are _not_ recoverable!*

## MySQL Setup

After the server is provisioned, we will log in to the server and install mysql.

1. Login to the server

    ```
    myserver login
    ```

1. Configure the mysql installation process

    ```
    # from the server
    sudo -s
    wget http://repo.mysql.com/mysql-apt-config_0.8.13-1_all.deb
    dpkg -i mysql-apt-config_0.8.13-1_all.deb
    ```

    1. From here, choose option 1, "MySQL Server & Cluster".
    1. Next choose version 5.7

1. Install mysql

    ```
    # still from the server
    apt update && apt install -y mysql-server
    ```

    Leave the root password blank

1. Setup your admin user

    1. Login to the mysql server

        ```
        # still logged in to the production server...
        mysql -uroot
        ```

    1. Create your admin mysql user

        ```
        CREATE USER you@localhost IDENTIFIED BY 'password';
        GRANT ALL on *.* TO zach@localhost WITH GRANT OPTION;
        ```

        Replacing `you` with your server username, and `password` with your
        admin db password (found with `myserver credentials`).

1. Logout of the server.

    ```
    exit
    ```
