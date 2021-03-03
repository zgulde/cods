# Laravel Deployment Guide

1. Create the site

    ```
    myserver site create -d php-site.com --php
    ```

1. Create the database for your application

    ```
    myserver db create -n my_database -u my_user
    ```

1. Push to deploy

    ```
    myserver site info -d php-site.com
    # add the git remote
    git push production main
    ```

1. Login to finalize setup

    ```
    myserver login
    ```

    ```
    cd /srv/php-site.com
    composer install
    cp .env.example .env
    ./artisan key:generate
    # edit .env for db secrets, environment, etc
    ```

1. Add an `cods.sh` script with `composer install` in it

    Create a file in your project root named `cods.sh` with the following
    contents:

    ```
    composer install
    ```

    This file will be run (i.e. `composer install` will run) whenever you push
    to the production remote and deploy the site.

