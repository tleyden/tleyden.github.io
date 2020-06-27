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

### Step 1: Launch a Lightsail instance

Lightsail seems like a good value since you can get a decent sized instance and a static IP for $5.

Login to the AWS console and create a Lightsail instance with the following specs:

* Blueprint: OS Only Ubuntu 18.04 LTS
* SSH key: upload your `~/.ssh/id_rsa.pub` (maybe make a copy and rename it with a better name to easily find it in the AWS console later)
* Instance Plan: $5/mo with 1GB or RAM, 1 vCPU, 40 GB SSD and 2 TB of transfer.  Ghost recommends at least 1 GB of RAM, so it's probably better to use this instance size or greater.
* Identify your instance: rabbit (or whatever you wanna call it!)

You should see the following:

![LightSailInstance.png](http://tleyden-misc.s3.amazonaws.com/blog_images/LightSail_Instance.png)

### Step: Add DNS A record

Go to your DNS register where you registered your blog domain name (eg, Namecheap), and add a new A record as follows:

![DNSARecord.png](http://tleyden-misc.s3.amazonaws.com/blog_images/AddDNSARecord.png)

* Use "blog" for the host if you want the blog named "blog.yourdomain.com", but you could also name it something else.
* Use the public static ip address from the Lightsail AWS console.

### Step 2: Install Ghost dependencies

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

### Step 3: Create ghost blog

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

Here is how I answered the setup questions, but you can customize to your needs:

* **Enter your blog URL:** http://blog1.domainA.com
* **Do you wish to setup Nginx?:** Yes
* **Do you wish to setup SSL?:** No
* **Do you wish to setup Systemd?:** Yes
* **Do you want to start Ghost?:** Yes 

I decided to setup SSL in a separate step rather than initially, but the more secure approach would be to use **https** instead, eg https://blog1.domainA.com for the blog URL, which will trigger SSL setup initially.

### Step 4: Create Ghost admin user

This part is a little scary, (and ghosts are scary), but Ghost basically puts your blog unprotected to the world without an admin user.  The first person that stumbles across it gets to become the admin user.  You want that to be you!

Quickly go to http://blog1.domainA.com and create the Ghost admin user.

### Step 5: Configure blog2 and map it's DNS

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


### References

* https://ghost.org/docs/install/ubuntu/
* https://forum.ghost.org/t/cannot-run-ghost-install-on-ubuntu-using-sqlite3/10129
* https://stanislas.blog/2018/03/migrating-ghost-from-mysql-to-sqlite/