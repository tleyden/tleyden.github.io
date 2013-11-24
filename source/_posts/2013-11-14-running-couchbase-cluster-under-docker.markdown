---
layout: post
title: "Running couchbase cluster under docker"
date: 2013-11-14 15:45
comments: true
categories: [docker, couchbase]
---

This tutorial will show you how to run a cluster of Couchbase Servers, where each node is running inside of a docker image.

![Diagram](http://cl.ly/image/2G0h381N3o42/docker%20couchbase%20cluster.png)

This probably looks like _a lot_ of layers, and you might be wondering if this will make your system crawl -- but bear in mind that the Docker virtualization model is very lightweight, and so basically everything under CoreOS has very little resource overhead.

## Install Docker and dependencies

If you are on OSX and don't have Docker installed, check out [Install Docker on OSX](http://tleyden.github.io/blog/2013/11/12/docker-on-osx/) before proceeding.

## Edit vagrant file to add port mappings

In order to access all the Couchbase Server nodes from the host, _which doesn't currently work_, you would need to add the following entries to your Vagrantfile:

```
config.vm.network "forwarded_port", guest: 8091, host: 8091
config.vm.network "forwarded_port", guest: 8092, host: 8092
config.vm.network "forwarded_port", guest: 11210, host:	11210
```

As mentioned, accessing all of the Couchbase Server nodes from the host does not currently work.  However, I think at least some of these entries are needed, so to be on the safe side just add all of them.

## Start CoreOS and ssh in

Execute the following commands in the directory where you have your CoreOS Vagrantfile.  In my case, I have it under `~/Tools/coreos-vagrant` and it contains a Vagrantfile, a README.md file, and a few others.

Start CoreOS

```
$ vagrant up
```

SSH into CoreOS

```
$ vagrant ssh
```

## Start docker image for a single node

Here's how to fire up the first docker image

```
docker run -i -t -d -p 11210:11210 -p 8091:7081 -p 8092:8092 dustin/couchbase:latest
```
and you should see:

```
Unable to find image 'dustin/couchbase:latest' (tag: latest) locally
Pulling repository dustin/couchbase
9e0279ab340d: Download complete
...
845987ce946b
```

Find the name of the docker instance by running `$ docker ps`

```
core@localhost ~ $ docker ps
CONTAINER ID        IMAGE                     COMMAND                CREATED              STATUS              PORTS                                                                      NAMES
845987ce946b        dustin/couchbase:latest   /bin/sh -c /usr/loca   About a minute ago   Up About a minute   0.0.0.0:11210->11210/tcp, 0.0.0.0:8091->7081/tcp, 0.0.0.0:8092->8092/tcp   purple_kangaroo
```

In this case it's *purple_kangaroo*. 

Now take a look at the logs for that docker instance:

```
core@localhost ~ $ docker logs purple_kangaroo
/opt/couchbase/etc/couchbase_init.d: 45: ulimit: error setting limit (Operation not permitted)
/opt/couchbase/etc/couchbase_init.d: 47: ulimit: error setting limit (Operation not permitted)
 * Started couchbase-server
Starting cluster
SUCCESS: init 127.0.0.1
SUCCESS: bucket-create
```

If you only want to run one Couchbase Server node, you are pretty much done and you can skip to the section below to login to the Couchbase Server admin

If you want to run a cluster of Couchbase Server nodes, read on.

## Start docker images for other nodes

```
$ docker run -i -t -d -link purple_kangaroo:alpha dustin/couchbase:latest
```

This will start another node that is linked to the initial node, and will be in the same cluster.  There is some Weird Magic behind the scenes that makes that all work.

# Go to Couchbase Server admin

Open [http://localhost:8091/](http://localhost:8091/) in your browser, and you should see a login screen, where the default credentials are Administrator/password. 

After you login, you should see the Admin UI with three nodes in your cluster:

![Screenshot](http://cl.ly/image/2K3i1v2w3H0E/Screen%20Shot%202013-11-14%20at%204.47.18%20PM.png)







