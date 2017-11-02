# Frequently Asked Questions

* [Do I need to create a new server (droplet) for every site I want to host?](#do-i-need-to-create-a-new-server-droplet-for-every-site-i-want-to-host)
* [How do I setup a new site?](#how-do-i-setup-a-new-site)
* [Can I use a subdomain?](#can-i-use-a-subdomain)
* [How do I enable https?](#how-do-i-enable-https)
* [How do I deploy changes to my site?](#how-do-i-deploy-changes-to-my-site)
* [Can I upload a `war` file directly (i.e. without using the git deployment)?](#can-i-upload-a-war-file-directly-ie-without-using-the-git-deployment)
* [Can I redeploy my project without a `git push`?](#can-i-redeploy-my-project-without-a-git-push)
* [I made a typo when setting up the database credentials. What do?](#i-made-a-typo-when-setting-up-the-database-credentials-what-do)
* [How can I find my server's ip address?](#how-can-i-find-my-servers-ip-address)
* [What is my git deployment remote?](#what-is-my-git-deployment-remote)
* [My site's not working.](#my-sites-not-working)

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
   `example.com/.config`

1. Add the git remote to your project and push

## Can I use a subdomain?

Yes! Assuming the DNS records are setup properly, you could host different
applications at `example.com`, `blog.example.com`, or even
`myawesome.blog.example.com`.

## How do I enable https?

**You can only do this if your DNS records are properly configured.**

```
./server site enablessl example.com
```

See the `HTTPS` section in the main README for more details

## How do I deploy changes to my site?

Short answer: push to your deployment remote.

If you are working by yourself, add and commit your code, and push to the
production remote.

If you are working on a team project, you should pull down the most recent
version of the master branch locally, and push that to your production remote.

See also, "Can I redeploy my project without a `git push`?"

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
- Setup the `.config` file on your server?
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

