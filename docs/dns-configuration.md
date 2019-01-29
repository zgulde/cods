# DNS Configuration

In short, the DNS records for the domain you wish to deploy to need to point to
the IP address of the server you setup with cods.

You could do this in a number of different ways, but this guide will give one
version of how to do so.

---

## Use Digital Ocean's Nameservers

1. From your domain registrar (i.e. the company you bought the domain from)
   point the DNS nameservers for that domain to digital ocean.

    We will detail the process for namecheap here, but other registrars will be
    similar.

    1. Go to your dashboard and click the "manage" button next to your domain

    2. Under "nameservers", change from "BasicDNS" to "custom"

    3. Enter in the following nameservers:

        ```
        ns1.digitalocean.com
        ns2.digitalocean.com
        ns3.digitalocean.com
        ```

    4. Make sure to click the green check mark to apply the changes

## Configuring an A Record for your domain

This process will cause all requests for your domain to go to your server.

1. [Go to digital ocean's networking page](https://cloud.digitalocean.com/networking)

1. Add your domain (without the `www` or `http`) under "Add a Domain"

1. Under "Create a New Record" choose the "A" record (this should be selected by
   default)

1. For the hostname, enter `@`

1. For "will direct to", choose your droplet

1. Leave the default TTL

1. Click the "Create Record" button

## Configure Subdomains

A simple way to have any and all subdomain requests go to the same place as your
server is to do the following

1. Create a new record for your domain 

1. Choose "CNAME" for the record type

1. For "Hostname", enter `*`

1. For "Is an Alias Of", enter "@"

1. Leave the default TTL

1. Click the "Create Record" button

More advanced configuration, for example, wanting a specific subdomain to go to
a different IP address, is beyond the scope of this guide.
