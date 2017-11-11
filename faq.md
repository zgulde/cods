# Frequently Asked Questions

* [How do I deploy changes to my site?](#how-do-i-deploy-changes-to-my-site)
* [Do I need to create a new server (droplet) for every site I want to host?](#do-i-need-to-create-a-new-server-droplet-for-every-site-i-want-to-host)
* [How do I setup a new site?](#how-do-i-setup-a-new-site)
* [Can I use a subdomain?](#can-i-use-a-subdomain)
* [How do I login to my server?](#how-do-i-login-to-my-server)
* [How do I login to my database?](#how-do-i-login-to-my-database)
* [How can I run a seeder script on my production database?](#how-can-i-run-a-seeder-script-on-my-production-database)
* [How do I enable https?](#how-do-i-enable-https)
* [Can I redeploy my project without a `git push`?](#can-i-redeploy-my-project-without-a-git-push)
* [I made a typo when setting up the database credentials. What do?](#i-made-a-typo-when-setting-up-the-database-credentials-what-do)
* [How can I find my server's ip address?](#how-can-i-find-my-servers-ip-address)
* [What is my git deployment remote?](#what-is-my-git-deployment-remote)
* [Can I upload a `war` file directly (i.e. without using the git deployment)?](#can-i-upload-a-war-file-directly-ie-without-using-the-git-deployment)
* [My site's not working.](#my-sites-not-working)
* [Can I view my site if the DNS records aren't properly configured?](#can-i-view-my-site-if-the-dns-records-arent-properly-configured)

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
    ./server site create example.com
    ./server db create example_db example_user
    ```

1. Login to the server and create `example.com/application.properties` and edit
   `example.com/config`

1. Add the git remote to your project and push

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

## How can I run a seeder script on my production database?

Run

```
./server db run example_db /local/path/to/seeder.sql
```

Replacing `example_db` and `/local/path/to/seeder.sql` with the name of your database
and the filepath to the seeder script you wish to run.

## How do I enable https?

**You can only do this if your DNS records are properly configured.**

```
./server site enablessl example.com
```

See the `HTTPS` section in the main README for more details

## Can I redeploy my project without a `git push`?
## I made a typo when setting up the database credentials. What do?

Login to the server and fix the typo. In general, if you change something that
is external to your project (i.e. not in the project's git repository), you can
redeploy the project by running:

```
./server site build example.com
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
./server site info example.com
```

Replacing `example.com` with the site you setup.

## Can I upload a `war` file directly (i.e. without using the git deployment)?

Yes, build the war, then run:

```
from ~/my-server
./server site deploy example.com ~/IdeaProjects/example-project/target/example-1.0-SNAPSHOT.war
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
./server tomcatlog
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
