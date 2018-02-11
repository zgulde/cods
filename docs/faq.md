# Frequently Asked Questions

* [How do I deploy changes to my site?](#how-do-i-deploy-changes-to-my-site)
* [Do I need to create a new server (droplet) for every site I want to host?](#do-i-need-to-create-a-new-server-droplet-for-every-site-i-want-to-host)
* [How do I setup a new site?](#how-do-i-setup-a-new-site)
* [Can I use a subdomain?](#can-i-use-a-subdomain)
* [How do I login to my server?](#how-do-i-login-to-my-server)
* [How do I login to my database?](#how-do-i-login-to-my-database)
* [How can I run a database migration on my production database?](#how-can-i-run-a-database-migration-on-my-production-database)
* [How can I run a seeder file for my production database?](#how-can-i-run-a-seeder-file-for-my-production-database)
* [How can I run a sql script on my production database?](#how-can-i-run-a-sql-script-on-my-production-database)
* [How do I enable https?](#how-do-i-enable-https)
* [Can I redeploy my project without a `git push`?](#can-i-redeploy-my-project-without-a-git-push)
* [I made a typo when setting up the database credentials. What do?](#i-made-a-typo-when-setting-up-the-database-credentials-what-do)
* [How can I find my server's ip address?](#how-can-i-find-my-servers-ip-address)
* [What is my git deployment remote?](#what-is-my-git-deployment-remote)
* [Can I upload a `war` file directly (i.e. without using the git deployment)?](#can-i-upload-a-war-file-directly-ie-without-using-the-git-deployment)
* [My site's not working.](#my-sites-not-working)
* [Can I view my site if the DNS records aren't properly configured?](#can-i-view-my-site-if-the-dns-records-arent-properly-configured)
* [How can I let my teammate push to deploy the project?](#how-can-i-let-my-teammate-push-to-deploy-the-project)
* [What is my password?](#what-is-my-password)

All the example command below assume you have already `cd`d into the directory
that contains your server setup. E.g.

```
cd ~/my-server
```

before running any commands below.

## How do I deploy changes to my site?

Short answer: add, commit, and push to your deployment remote.

If you are working by yourself, simply add and commit your code (possibly merge
a branch into `master`), and push to the production remote.

If you are working on a team project, you should pull down the most recent
version of the master branch locally, and push that to your production remote.

## Do I need to create a new server (droplet) for every site I want to host?

No! You can host multiple sites on the same server. The server setup and
provisioning is a one time process, once your server is setup, you can create
additional sites with the `./server site` (and probably also `./server db`)
commands.

## How do I setup a new site?

See the README or the deployment guide for more detailed instructions, but in
short (assuming the server is already setup and provisioned):

1. Do any necessary DNS record configuration

1. Make sure your project builds as a `war` and has a `.build_config` file

1. Create the site and database on the server

    ```
    ./server site create -d example.com
    ./server db create -d example_db -u example_user
    ```

1. Login to the server and create `example.com/application.properties` and edit
   `example.com/config`

1. Add the git deployment remote to your project and push

## Can I use a subdomain?

Yes! Assuming the DNS records are setup properly, you could host different
applications at `example.com`, `blog.example.com`, or even
`myawesome.blog.example.com`.

## How do I login to my server?

Run

```
./server login
```

---

Really this is just running the `ssh` command, you could also run

```
ssh USERNAME@IP_ADDRESS
# OR
ssh USERNAME@DOMAIN # assuming DNS is already configured
```

replacing `USERNAME` and `IP_ADDRESS` with your values

## How do I login to my database?

Have your database administrator password ready, and run:

```
./server db login
```

## How can I run a database migration on my production database?
## How can I run a seeder file for my production database?
## How can I run a sql script on my production database?

The easiest thing to do is to transfer the script to the server and run it
there.

```
./server upload -f /local/path/to/my-script.sql
./server login

# from the server
mysql -p < my-script.sql # you'll be promted for your db password
```

## How do I enable https?

**You can only do this if your DNS records are properly configured.**

```
./server site enablessl -d example.com
```

See the `HTTPS` section in the main README for more details

## Can I redeploy my project without a `git push`?
## I made a typo when setting up the database credentials. What do?

Login to the server and fix the typo.

```
./server login
nano /srv/example.com/application.properties
exit
```

In general, if you change something that is external to your project (i.e. not
in the project's git repository), you can redeploy the project by running:

```
./server site build -d example.com
```

This will trigger the same script that runs whenever you push to the deployment
remote.

## How can I find my server's ip address?

Run

```
./server info
```

## What is my git deployment remote?

Run

```
./server site info -d example.com
```

Replacing `example.com` with the site you setup.

## Can I upload a `war` file directly (i.e. without using the git deployment)?

Yes, build the war, then run:

```
from ~/my-server
./server site deploy -d example.com -f /path/to/the/file.war
```

Replacing `example` with the relevant values for your project.

## My site's not working.

That's not really a question, but the answer to the implied question depends on
how far along in the process you are.

### I haven't yet seen my site live

Did you:

- Change your class with the `main` method and commit it?
- Change the `packaging` in your `pom.xml`? Change it from `jar` to `war` and
  make sure to commit the change.
- Add the `.build_config` file and commit it?
- Setup the site on the server? I.e. run `./server site create`
- Setup a database on the server? I.e. run `./server db create`
- Setup the production `application.properties` file on your server?
- Setup the `config` file on your server?
- Push your changes?

### The site was working, but no longer is

**Can you reproduce it locally?**

Don't try to troubleshoot deployment problems in production, rather you should
try and reproduce the problem locally, fix it, and the deploy the fixed version
of your application.

**Check the logs!**

```
./server log:cat
```

Will dump out the tomcat log file located on your server at
`/opt/tomcat/logs/catalina.out`. You will see any exceptions that happen in
production and their stack traces here.

*Note you will need your server admin password for this operation.*

## Can I view my site if the DNS records aren't properly configured?

Yes, but it will only work on your laptop. In order for other people to view
your site, the DNS records will need to be configured to point to your server.

To "fake" the DNS records on your machine:

1. Open the file `/etc/hosts`

    This file is probably locked down, and you will most likely need to enter
    your computer's administrator password to edit it.

1. Add a line that looks like the following:

    ```
    123.123.123.123 example.com
    ```

    Replacing `123.123.123.123` with your server's IP address, and `example.com`
    with your domain name.

    *Note that if you want to "fake" a subdomain, you will need a separate entry
    (i.e. line) for each subdomain.*

Now you should be able to visit your site (assuming everything else is setup
properly).

Keep in mind that you will only be able to visit the site on your laptop, you
will **not** be able to enable https for the domain until the DNS records are
setup.

Once the DNS records are setup properly, or to test if they are, you can remove
the same line from `/etc/hosts`.

## How can I let my teammate push to deploy the project?

See also the relevant section in the main README.

1. Save your teammate's public ssh key locally on your computer.

    If your teammate has their ssh keys setup on GitHub, you can go to

        https://github.com/USERNAME.keys

    replacing `USERNAME` with your teammate's github username.

    Copy the key(s) to your clipboard, then in a terminal (assuming you are
    using MacOS)

        pbpaste > ~/my-friends-ssh-key.pub

    This will create a file named `my-friends-ssh-key.pub` in your home
    directory. (You could choose a different filename if you so desire.)

1. Use the `adduser` subcommand to create the user account on your server.

    You may also wish to create a database admin account for your teammate at
    this time. See the main README for more details on this step.

1. Have your teammate clone this tool and setup their `.env` file.

    See the main README for details of what this `.env` file should contain

    ```
    git clone https://github.com/zgulde/tomcat-setup ~/shared-server
    cd ~/shared-server
    nano .env
    ```

1. Have your teammate add the appropriate deployment remote to their project.

    You can obtain the deployment remote (and the git cli command to add it)
    through the `site info` subcommand.

    For example, if the project was named `example` and was deployed to
    `example.com`, you might run the following commands:

    ```
    cd ~/shared-server
    ./server site info -d example.com
    ```

    copy the command for adding the deployment remote, then...

    ```
    cd ~/IdeaProjects/example
    ```

    and paste the deployment remote adding command

Now your teammate can push to `production` as well!

## What is my password?

In general, and commands that you run that prompt for a password will need your
`sudo` password (i.e. the server admin password). The only exception to this is
any command run with the `db` subcommand, these will all need your database
admin password.

By default, when a server is setup, a file located at
`~/my-server/credentials.txt` is created. This file has both your user account's
sudo password, as well as the admin password for the mysql installation on your
server.

If you deleted/moved this file, or changed your password, and do not remember
it, (by design) there is nothing you can do to recover it.

## Can I use tab completion to help me out?

Yes! Add the following line to the end of your `.bashrc` (if you're on Linux) or
`.bash_profile` (if you're on Mac):

```
eval "$(myserver bash-completion)"
```

Where `myserver` is the name of your server command.

Close any open terminals, and when you start a new one, you will be able to use
tab completion for all subcommands.
