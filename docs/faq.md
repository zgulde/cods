# Frequently Asked Questions

* [How do I deploy changes to my site?](#how-do-i-deploy-changes-to-my-site)
* [Do I need to create a new server (droplet) for every site I want to host?](#do-i-need-to-create-a-new-server-droplet-for-every-site-i-want-to-host)
* [How do I setup a new site?](#how-do-i-setup-a-new-site)
* [How do I create a static site?](#how-do-i-create-a-static-site)
* [Can I use a subdomain for my site?](#can-i-use-a-subdomain-for-my-site)
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
* [My site's not working.](#my-sites-not-working)
    * [I haven't yet seen my site live](#i-havent-yet-seen-my-site-live)
    * [The site was working, but no longer is](#the-site-was-working-but-no-longer-is)
* [Can I view my site if the DNS records aren't properly configured?](#can-i-view-my-site-if-the-dns-records-arent-properly-configured)
* [How can I let my teammate push to deploy the project?](#how-can-i-let-my-teammate-push-to-deploy-the-project)
* [What is my password?](#what-is-my-password)
* [Can I use tab completion to help me out?](#can-i-use-tab-completion-to-help-me-out)
* [How can I upload really big files to my site?](#how-can-i-upload-really-big-files-to-my-site)
* [Do I need to do anything special to use ${fancy_js_framework}?](#do-i-need-to-do-anything-special-to-use-fancy_js_framework)
* [How can I do client-side routing?](#how-can-i-do-client-side-routing)
* [Do I need to do anything differently if I have multiple Java installations?](#do-i-need-to-do-anything-differently-if-i-have-multiple-java-installations)

All the example command below assume your server management command is named
`myserver`.

## How do I deploy changes to my site?

Short answer: add, commit, and push to your deployment remote.

If you are working by yourself, simply add and commit your code (possibly merge
a branch into `main`), and push to the production remote.

If you are working on a team project, you should pull down the most recent
version of the main branch locally, and push that to your production remote.

## Do I need to create a new server (droplet) for every site I want to host?

No! You can host multiple sites on the same server. The server setup and
provisioning is a one time process, once your server is setup, you can create
additional sites with the `myserver site` (and probably also `myserver db`)
commands.

## How do I setup a new site?

See the README or the deployment guide for more detailed instructions, but in
short (assuming the server is already setup and provisioned) (this assumes the
new site you want to deploy is a spring boot application):

1. Do any necessary DNS record configuration

1. Make sure your project builds as a `jar` and has a `.cods` file

1. Create the site and database on the server

    ```
    myserver site create --domain example.com --java --spring-boot
    myserver db create --name example_db --user example_user
    ```

1. Login to the server and create `/srv/example.com/application.properties` and edit
   `/srv/example.com/config`

    *if you used the `--spring-boot` flag in the step above, you just need to
    edit the `application.properties`, the `config` file should be good to go.*

1. Add the git deployment remote to your project and push

## How do I create a static site?

See the usage guide for more info, but in short:

1. Setup the site

    ```
    myserver site create --domain my-static-site.com --static
    ```

1. Add the git deployment remote to your project and push

    ```
    myserver site info --domain my-static-site.com
    ```

    will show you the git deployment remote

By default, the contents of the repository will be served. If you have a build
step for your static site, checkout the usage guide to get it setup.

## Can I use a subdomain for my site?

Yes! Assuming the DNS records are setup properly, you could host different
applications at `example.com`, `blog.example.com`, or even
`myawesome.blog.example.com`.

## How do I login to my server?

Run

```
myserver login
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
myserver db login
```

## How can I run a database migration on my production database?
## How can I run a seeder file for my production database?
## How can I run a sql script on my production database?

The easiest thing to do is to transfer the script to the server and run it
there.

```
myserver upload -f /local/path/to/my-script.sql
myserver login

# from the server
mysql -p < my-script.sql # you'll be promted for your db password
```

## How do I enable https?

**You can only do this if your DNS records are properly configured.**

```
myserver site enablehttps -d example.com
```

See the `HTTPS` section in the main README for more details

You can also do this when setting up a site:

```
myserver site create -d example.com --enable-https
```

## Can I redeploy my project without a `git push`?
## I made a typo when setting up the database credentials. What do?

Edit the file on the server and then re-start your site. For example:

```
myserver run nano /srv/example.com/application.properties
myserver site build -d example.com
```

In general, if you change something that is external to your project (i.e. not
in the project's git repository), you can redeploy the project by running:

```
myserver site build -d example.com
```

This will trigger the same script that runs whenever you push to the deployment
remote.

## How can I find my server's ip address?

Run

```
myserver info
```

## What is my git deployment remote?

Run

```
myserver site info -d example.com
```

Replacing `example.com` with the site you setup.

## My site's not working.

That's not really a question, but the answer to the implied question depends on
how far along in the process you are.

### I haven't yet seen my site live

If you are deploying a spring boot application, did you:

- Add the `.cods` file and commit it?
- Setup the site on the server? I.e. run `myserver site create`
- Setup a database on the server? I.e. run `myserver db create`
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
myserver site logs --domain example.com
```

Will dump out the logs on your server for the site. You will see any exceptions
that happen in production and their stack traces here, along with timestamps
that indicate when this happened.

Also,

```
myserver site logs --domain example.com --follow
```

will let you watch the logs in real time from your terminal (press Ctrl-C to
exit).

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

See also the relevant section in the usage guide.

0. Make sure the desired teammate has their public ssh key setup on their github
   account

**The person that currently controls the server:**

run

```
myserver user add --github-username=USERNAME
```

replacing `USERNAME` with your teammte's github username

the script will pull the teammate's public ssh keys from github and setup a user
account with an autogenerated password for them.

**The person being added**

Run

```
cods add shared-server
```

Where `shared-server` is the name of the command that will be created to
interact with the shared server.

You will be prompted for a username for the server, this is your github username
that your teammate used in the previous step.

Next run

```
shared-server site info --domain example.com
```

relacing `DOMAIN` with the name of the domain you want to push to deploy to

you should see the command to add the `production` remote, and you can add the
production remote to your project as well

## What is my password?

```
myserver credentials
```

In general, and commands that you run that prompt for a password will need your
`sudo` password (i.e. the server admin password). The only exception to this is
any command run with the `db` subcommand, these will all need your database
admin password.

By default, when a server is setup, a file located at
`~/.config/cods/myserver/credentials.txt` is created (here `myserver` could be a
different command name depending on what you've chosen). This file has both your
user account's sudo password, as well as the admin password for the mysql
installation on your server, and any further generated passwords. The command
above simply displays the contents of the `credentials.txt` file.

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
tab completion for all subcommands and arguments.

## How can I upload really big files to my site?

By default, the nginx configuration for each site allows a maximum upload size
of 10MB. If your site needs to handle files larger than this, you should edit
the nginx config for your site, then restart nginx.

```
# this command will show you the path to the nginx config file on the server
myserver site info --domain uploads.example.com

myserver login
...
# edit the file (you'll need admin access to edit the file)
sudo nano /etc/nginx/sites-available/uploads.example.com
# validate nginx config (checks for syntax errors in the config file)
sudo nginx -t
# restart nginx to use the new config
sudo systemctl restart nginx
```

You'll want to change this line in the config file:

```
client_max_body_size 10m;
```

## Do I need to do anything special to use ${fancy_js_framework}?
## How can I do client-side routing?

If you are working on an application that does client-side url routing (i.e. the
paths for your app are handled in the client side js), you'll probably want
nginx to rewrite missing urls to your `index.html` file. The nginx config that
is setup for a static site contains comments and commented out configuration
that explain how to do this.

Run the `site info` command to find the path to your site's nginx config file,
then edit the nginx config file (read the comments in the `location /`), and
finally, restart nginx and you should be good to go.

```
myserver site info -d example.com
myserver run sudo nano /etc/nginx/sites-available/example.com
myserver restart --service=nginx
```

## How do I Work With Multiple Java Versions?

```
myserver switch-java-version
```

Will control which version of java is running on the server.

### For Local Development

If you have multiple versions of java installed and you are deploying a spring
boot v1.x application, you'll want to specify that you are using Java 8 when you
run your application from the command line.

This consists of two steps:

1. Configuring Maven

    ```
    echo "JAVA_HOME=$(/usr/libexec/java_home -v 1.8)" > ~/.mavenrc
    ```

    This command will create a file named `~/.mavenrc` in your home directory
    that will specify that maven should use Java 8 when running from the command
    line

1. Configuration for the `java` command

    We'll want to specify that we want to use java 8 when we run the `java`
    command.

    ```
    export JAVA_HOME="$(/usr/libexec/java_home -v 1.8)"
    ```

    This will make the `java` command use java 8 **for the current terminal
    session**. If you open a new terminal, you'll need to run the command again.

    Alternatively, if you want to always use java 8 when running the `java`
    command, you could add the line above to your `.bashrc` (linux) or
    `.bash_profile` (MacOS)

