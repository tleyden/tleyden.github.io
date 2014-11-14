---
layout: post
title: "Running CBFS"
date: 2014-11-14 06:43
comments: true
categories: couchbase, cbfs, docker, coreos
---

This will walk you through getting a cbfs cluster up and running.

## What is CBFS?

cbfs is a distributed filesystem on top of Couchbase Server, not unlike Mongo's GridFS or Riak's CS.  It's currently an experimental "skunkworks" project and hasn't quite reached official project status. 

Here's a typical deployment architecture:

![cbfs overview](http://tleyden-misc.s3.amazonaws.com/blog_images/cbfs-overview.png) 

Although not shown, all cbfs daemons can communicate with all Couchbase Server instances.

It is not required to run cbfs on the same machine as Couchbase Server, but it *is* meant to be run in the same data center as Couchbase Server.  

If you want a deeper understanding of how cbfs works, check the [cbfs presentation](http://labs.couchbase.com/cbfs/) or this [blog post](http://dustin.sallings.org/2012/09/27/cbfs.html).

## Kick off a Couchbase Cluster

cbfs depends on having a Couchbase cluster running in the same data center.

Follow all of the steps in [Running Couchbase Cluster Under CoreOS on AWS](http://tleyden.github.io/blog/2014/11/01/running-couchbase-cluster-under-coreos-on-aws/) to kick off a 3 node Couchbase cluster.

## Add security groups

A few ports will need to be opened up for cbfs.  

Go to the AWS console andeEdit the Couchbase-CoreOS-CoreOSSecurityGroup-xxxx security group and add the following rules: 

```
Type             Protocol  Port Range Source  
----             --------  ---------- ------
Custom TCP Rule  TCP       8484       Custom IP: sg-6e5a0d04 (copy and paste from port 4001 rule)
Custom TCP Rule  TCP       8423       Custom IP: sg-6e5a0d04 
```

At this point your security group should look like this:

![security group](http://tleyden-misc.s3.amazonaws.com/blog_images/security_group_cbfs.png)

# Create a new bucket for cbfs

**Open Couchbase Server Admin UI**

In the AWS EC2 console, find the public IP of one of the instances (it doesn't matter which)

In your browser, go to `http://<public_ip>:8091/`

**Create Bucket**

Go to Data Buckets / Create New Bucket

Enter **cbfs** for the name of the bucket.

Leave all other settings as default.

![create bucket](http://tleyden-misc.s3.amazonaws.com/blog_images/cbfs_create_bucket.png)

## ssh in

In the AWS EC2 console, find the public IP of one of the instances (it doesn't matter which)

ssh into one of the machines:

```
$ ssh -A core@<public_ip>
```

## Run cbfs

**Create a volume dir**

Since the fileystem of a docker container is not meant for high throughput io, a volume should be used for cbfs.

Create a directory on the host OS (eg, on the Core OS instance)

```
$ sudo mkdir -p /var/lib/cbfs/data
$ sudo chown -R core:core /var/lib/cbfs
```

This will be mounted by the docker container in the next step.

**Start cbfs**

```
$ ip=$(hostname -i | tr -d ' ')
$ sudo docker run --net=host \
  -v /var/lib/cbfs/data:/var/lib/cbfs/data \
  tleyden5iwx/cbfs \
  cbfs \
  -nodeID=$ip \
  -bucket=cbfs \
  -couchbase=http://$ip:8091/ \
  -root=/var/lib/cbfs/data \
  -viewProxy
```

You should see output like:

```
2014/11/14 23:18:58 Connecting to couchbase bucket cbfs at http://10.51.177.81:8091/
2014/11/14 23:18:58 Error checking view version: MCResponse status=KEY_ENOENT, opcode=GET, opaque=0, msg: Not found
2014/11/14 23:18:58 Installing new version of views (old version=0)
2014/11/14 23:18:58 Listening to web requests on :8484 as server 10.51.177.81
2014/11/14 23:18:58 Error removing 10.51.177.81's task list: MCResponse status=KEY_ENOENT, opcode=DELETE, opaque=0, msg: Not found
2014/11/14 23:19:05 Error updating space used: Expected 1 result, got []
```

## Run cbfs client

On a new shell, ssh into the same coreos instance where you just launched cbfs.  The following commands assume you are on CoreOS (not in the docker container)

```
$ sudo docker run -ti --net=host tleyden5iwx/cbfs /bin/bash
```

**Upload a file**

From within the docker container launched in the previous step:

```
# echo "foo" > foo
# ip=$(hostname -i | tr -d ' ')
# cbfsclient http://$ip:8484/ upload foo /foo
```

There should be no errors.  On the `cbs` daemon console, you should see log messages like:

```
2014/11/14 21:51:43 Recorded myself as an owner of e242ed3bffccdf271b7fbaf34ed72d089537b42f: result=success
```

**List directory**

```
# cbfsclient http://$ip:8484/ ls /
foo
```

It should list the foo file we uploaded earlier.

Congratulations!  You now have cbfs up and running on a single node.

## Run cbfs on other nodes

At this point, the cbfs daemon is only running on a single node.  You might have even noticed errors like this already:

```
2014/11/14 23:24:11 Error running task ensureMinReplCount: Not enough nodes to increase repl count.
```

You will want to run cbfs on all of the nodes in your cluster so that it can replicate files and provide robustness against data loss.  (and make those ensureMinReplCount errors go away)

On the other two CoreOS intances:

* **Create a volume dir** as described above
* **Start cbfs** as described above

You now have cbfs up and running on all nodes!


## References

* [cbfs - a couchbase large object store](http://dustin.sallings.org/2012/09/27/cbfs.html)
* [cbfs presentation](http://labs.couchbase.com/cbfs/)
* [cbfs binary downloads](http://cbfs-ext.hq.couchbase.com/dist/)
* [cbfs github repo](http://github.com/couchbaselabs/cbfs)
* [cbfs question](https://github.com/couchbaselabs/cbfs/issues/132)