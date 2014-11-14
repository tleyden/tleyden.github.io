---
layout: post
title: "Running CBFS"
date: 2014-11-14 06:43
comments: true
categories: couchbase, cbfs, docker, coreos
---

This will walk you through getting a cbfs cluster up and running.

## What is CBFS?

cbfs is a distributed filesystem on top of Couchbase Server, not unlike Mongo's GridFS or Riak's CS products.  It's an experimental "skunkworks" project, that hasn't quite reached official project status. 

Here's a typical deployment architecture:

![cbfs overview](http://tleyden-misc.s3.amazonaws.com/blog_images/cbfs-overview.png) 

but other valid architectures exist.  You might want to run the Couchbase Server and cbfsd nodes on different machines for example.

If you want a deeper understanding, check the [cbfs presentation](http://labs.couchbase.com/cbfs/) or this [blog post](http://dustin.sallings.org/2012/09/27/cbfs.html).

## Kick off a Couchbase Cluster

See [Running Couchbase Cluster Under CoreOS on AWS](http://tleyden.github.io/blog/2014/11/01/running-couchbase-cluster-under-coreos-on-aws/) for instructions on kicking off a 3 node Couchbase cluster.

## ssh in

ssh into one of the machines:

```
$ ssh -A core@ec2-54-147-199-230.compute-1.amazonaws.com
```

## Run a docker image

Since we're on CoreOS, we'll need to run cbfs in a Docker container.  There isn't a pre-built docker image for cbfs yet, so we'll run Ubuntu and install cbfs on it.

```
$ sudo docker run -ti --net=host ubuntu:14.04 /bin/bash
```

*The reason I'm using `--net=host` is to avoid any issues of cbfs nodes not being able to see eachother over the network by letting it use the host's networking rather than the docker container instance being assigned it's own ip address.  I don't know if this is strictly necessary.*


## Install cbfs

Let's build cbfs from source.

**First install dependencies**

```
# apt-get update
# apt-get install golang git
```

**Configure Go**

```
# mkdir /opt/go
# echo "export GOPATH=/opt/go" >> /etc/profile
# echo "export PATH=\$PATH:$GOPATH/bin" >> /etc/profile
# source /etc/profile
```

**Create a data dir**

```
# mkdir -p /var/lib/cbfs/data
```

*Warning: in fact, this should be using Docker volumes rather than the container fileystem.  I need to loop back and update this blog*

**Go get cbfs**

```
# go get -u -v -t github.com/couchbaselabs/cbfs
```

At this point you should have the cbfs binary built and on your $PATH.  Run `cbfs -h` and it will output the help options.

## Run cbfs

**Start cbfs daemon**

Since Couchbase Server is already running in a different docker container on the same host OS, we can just use the ip of the current host we are on.

```
# ip=$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
# cbfs -nodeID=$ip \
       -bucket=cbfs \
       -couchbase=http://$ip:8091/
       -root=/var/lib/cbfs/data \
       -viewProxy
```

**Start more cbfs daemons**

On a new shell, ssh into the same coreos instance.  The following commands assume you are on CoreOS (not in the docker container)

Run `fleetctl list-machines` to find the other hosts.

```
$ fleetctl list-machines
MACHINE		IP		METADATA
3997ac72...	10.203.135.243	-
9fe66146...	10.231.38.249	-
b78a41ec...	10.187.52.156	-
```

Now ssh into one of the other hosts:

```
$ fleetctl ssh 9fe66146
```

**Create a volume dir**

```
$ sudo mkdir -p /var/lib/cbfs/data
$ sudo chown core:core /var/lib/cbfs/data
```

**Start cbfs**

```
$ ip=$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
$ sudo docker run --net=host -v /var/lib/cbfs/data:/var/lib/cbfs/data tleyden5iwx/cbfs \
                  -nodeID=$ip \
                  -bucket=cbfs \
       		  -couchbase=http://$ip:8091/
       		  -root=/var/lib/cbfs/data \
       		  -viewProxy
 
```

## Run cbfs client

On a new shell, ssh into the one of the coreos instances where you launched cbfs.  The following commands assume you are on CoreOS (not in the docker container)

```
$ sudo docker run -ti --net=host tleyden5iwx/cbfs /bin/bash
```

**Get the cbfs client**

```
# sudo apt-get install -y mercurial
# go get -u -v -t github.com/couchbaselabs/cbfs/tools/cbfsclient
```

**Run the cbfs client**

```
cbfsclient http://localhost:8484/ info
```


## References

* [cbfs - a couchbase large object store](http://dustin.sallings.org/2012/09/27/cbfs.html)
* [cbfs presentation](http://labs.couchbase.com/cbfs/)
* [cbfs binary downloads](http://cbfs-ext.hq.couchbase.com/dist/)
* [cbfs github repo](http://github.com/couchbaselabs/cbfs)