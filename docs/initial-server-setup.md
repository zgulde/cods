# Initial Server Setup

This setup guide will provide instructions for digital ocean, but, in theory,
this tool should be able to be used with any VPS provider that gives you root
ssh access to a server.

1. Sign up for digital ocean

1. Create a droplet on digitalocean.com

    A "droplet" is what digital ocean calls it's virtual servers.

    Choose Ubuntu 16.04x64 as the operating system, and the $5/month, 1GB RAM
    option for the size of the server.

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

