---
layout: post
title: "Installing Ghost on AWS Lightsail with SQLite"
date: 2020-06-27 09:59
comments: true
categories: 
---

Here are my requirements for a Ghost blogging platform backend:

* Cheap - ideally under $5 / month
* Ability to setup multiple blogs if I later want to add a new blog hosted on a different domain: so blog1.domainA.com + and blog2.domainB.com, without increasing cost.
* Easy to manage and backup

Non-requirements:

* High traffic
* Avoiding CLI or some server management (would be nice, but does that exist for < $5 month?)

And here is the tech stack:

* AWS Lightsail instance running Ubuntu 18
* SQLite
* Nginx
* Node.js
* Ghost Node.js module(s)

SQLite was chosen over MySQL since this is one less "moving part" and slightly easier to manage.  See [this blog post](https://stanislas.blog/2018/03/migrating-ghost-from-mysql-to-sqlite/) for the rationale.

### Launch a Lightsail instance

Lightsail seems like a good value since you can get a decent sized instance and a static IP for $5.

Login to the AWS console and create a Lightsail instance with the following specs:

* Blueprint: OS Only Ubuntu 18.04 LTS
* SSH key: upload your `~/.ssh/id_rsa.pub` (maybe make a copy and rename it with a better name to easily find it in the AWS console later)
* Instance Plan: $5/mo with 1GB or RAM, 1 vCPU, 40 GB SSD and 2 TB of transfer.  Ghost recommends at least 1 GB of RAM, so it's probably better to use this instance size or greater.
* Identify your instance: rabbit (or whatever you wanna call it!)

You should see the following:

![LightSailInstance.png](http://tleyden-misc.s3.amazonaws.com/blog_images/LightSail_Instance.png)

### Create a static ip

Go to the Lightsail **Networking** section, and choose "Attach static ip".  Associate the static ip with the lightsail instance, and make a note of it as you will need in the next step.

### Add DNS A record

Go to your DNS register where you registered your blog domain name (eg, Namecheap), and add a new A record as follows:

![DNSARecord.png](http://tleyden-misc.s3.amazonaws.com/blog_images/AddDNSARecord.png)

* Use "blog" for the host if you want the blog named "blog.yourdomain.com", but you could also name it something else.
* Use the public static ip address created in the previous step.

### Install Ghost dependencies

ssh in via `ssh ubuntu@<your ligthsail instance ip>`

Update the apt package list:

```
$ sudo apt-get update
```

Install nginx:

```
$ sudo apt-get install -y nginx
$ sudo ufw allow 'Nginx Full'
```

Install nodejs:

Add the NodeSource APT repository for Node 12, then install nodejs

```
$ curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash
$ sudo apt-get install -y nodejs
```

Install Ghost-CLI

```
$ sudo npm install ghost-cli@latest -g
```

### Create ghost blog

Create a directory to hold the blog:

```
$ sudo mkdir -p /var/www/ghost/blog1
$ sudo chown ubuntu:ubuntu /var/www/ghost/blog1
$ sudo chmod 775 /var/www/ghost/blog1/
$ cd /var/www/ghost/blog1/
```

Install Ghost:

```
$ ghost install --db sqlite3
```

If you get an error about the node.js version being out of date, see the "Error installing ghost due to node.js being out of date" section below.

Here is how I answered the setup questions, but you can customize to your needs:

* **Enter your blog URL:** http://blog1.domainA.com
* **Do you wish to setup Nginx?:** Yes
* **Do you wish to setup SSL?:** No
* **Do you wish to setup Systemd?:** Yes
* **Do you want to start Ghost?:** Yes 

I decided to setup SSL in a separate step rather than initially, but the more secure approach would be to use **https** instead, eg https://blog1.domainA.com for the blog URL and answer Yes to the setup SSL question, which will trigger SSL setup initially.

If you do setup SSL, you will need to open port 443 in the Lightsail console, otherwise it won't work.  See the "Setup SSL" section below for instructions.


### Create Ghost admin user

This part is a little scary, (and ghosts are scary), but Ghost basically puts your blog unprotected to the world without an admin user.  The first person that stumbles across it gets to become the admin user.  You want that to be you!

Quickly go to http://blog1.domainA.com and create the Ghost admin user.

### Configure blog2 and map it's DNS

Go to your DNS register where you registered your blog domain name (eg, Namecheap), and add a new A record as follows:

* Use "blog" for the host if you want the blog named "blog.domainB.com", but you could also name it something else.
* Use the public static ip address from the Lightsail AWS console.

```
$ sudo mkdir -p /var/www/ghost/blog2
$ sudo chown ubuntu:ubuntu /var/www/ghost/blog2
$ sudo chmod 775 /var/www/ghost/blog2/
$ cd /var/www/ghost/blog2/
```

Install Ghost:

```
$ ghost install --db sqlite3
```

Use the same steps above, except for the blog URL use: http://blog.domainB.com

### Congrats!

You now have two separate Ghost blogging sites setup on a single $5 / mo AWS Lightsail instance.

### Appendix

#### Error installing ghost due to node.js being out of date

If you see this error:

```
$ ghost install --db sqlite3
You are running an outdated version of Ghost-CLI.
It is recommended that you upgrade before continuing.
Run `npm install -g ghost-cli@latest` to upgrade.

✔ Checking system Node.js version - found v12.22.10
✔ Checking logged in user
✔ Checking current folder permissions
✔ Checking system compatibility
✔ Checking memory availability
✔ Checking free space
✔ Checking for latest Ghost version
✔ Setting up install directory
✖ Downloading and installing Ghost v5.20.0
A SystemError occurred.

Message: Ghost v5.20.0 is not compatible with the current Node version. Your node version is 12.22.10, but Ghost v5.20.0 requires ^14.17.0 || ^16.13.0

Debug Information:
    OS: Ubuntu, v18.04.1 LTS
    Node Version: v12.22.10
    Ghost-CLI Version: 1.18.1
    Environment: production
    Command: 'ghost install --db sqlite3'

Try running ghost doctor to check your system for known issues.

You can always refer to https://ghost.org/docs/ghost-cli/ for troubleshooting.
```

##### Fix option #1 - specify an older version of ghost

Find an older version of ghost that is compatible with the node.js you have installed, then specify that version of ghost when installing it:

```
$ ghost install 4.34.3 --db sqlite3
```

How do you find that version?  I happened to have another blog folder that I had previously installed, so I just used that.  Maybe on the ghost website they have a compatibility chart.

The downside of this approach is that you won't have the latest and greatest version of ghost, including [security updates](https://github.com/TryGhost/Ghost/security/advisories/GHSA-7v28-g2pq-ggg8).  The upside though is that you won't break any existing ghost blogs on the same machine by upgrading node.js.


##### Fix option #2 - upgrade to a later node.js and retry

In the error above, it mentions that ghost requires node.js 14.17.0 or above.  

The downside is that this could potentially break other existing ghost blogs on the same machine that are not compatible with the later version of node.js.  Using containers to isolate dependencies would be beneficial here.

Upgrade to that version of node.js based on [these instructions](https://ghost.org/docs/reinstall/):

```
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs
```

Run `node -v` to verify that you're running a recent enough version:

```
$ node -v
v14.20.1
```

Update the ghost cli version:

```
sudo npm install -g ghost-cli@latest
```

Retry the ghost install command:

```
ghost install --db sqlite3
```

and this time it should not complain about the node.js version.


#### Setup SSL

During installation, you can answer "Yes" to setup SSL, and it will ask you for your email and use [letsencrypt](http://letsencrypt.org) to generate a certificate for you.  See [this page](https://ghost.org/integrations/lets-encrypt/) for more details.

But you must also open port 443 in your Lightsail firewall, otherwise it won't work.

![Screen Shot 2022-10-25 at 12 53 32 PM](https://user-images.githubusercontent.com/296876/197869779-dd7f5ce8-8815-4895-9f87-0837c435a0e4.png)




### References

* https://ghost.org/docs/install/ubuntu/
* https://forum.ghost.org/t/cannot-run-ghost-install-on-ubuntu-using-sqlite3/10129
* https://stanislas.blog/2018/03/migrating-ghost-from-mysql-to-sqlite/