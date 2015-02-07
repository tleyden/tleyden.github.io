---
layout: post
title: "Running Couchbase Cluster Under CoreOS on AWS"
date: 2014-11-01 12:16
comments: true
categories: docker coreos aws couchbase
---

Here are instructions on how to fire up a Couchbase Server cluster running under CoreOS on AWS CloudFormation.  You will end up with the following system:

![architecture diagram](http://tleyden-misc.s3.amazonaws.com/blog_images/couchbase-coreos-onion.png)

## Launch CoreOS instances via AWS Cloud Formation

Click the "Launch Stack" button to launch your CoreOS instances via AWS Cloud Formation:

[<img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png">](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#cstack=sn%7ECouchbase-CoreOS%7Cturl%7Ehttp://tleyden-misc.s3.amazonaws.com/couchbase-coreos/couchbase_server.template)

*NOTE: this is hardcoded to use the us-east-1 region, so if you need a different region, you should edit the URL accordingly*

Use the following parameters in the form:

* **ClusterSize**: 3 nodes (default)
* **Discovery URL**:  as it says, you need to grab a new token from https://discovery.etcd.io/new and paste it in the box.
* **KeyPair**:  use whatever you normally use to start EC2 instances.  For this discussion, let's assumed you used `aws`, which corresponds to a file you have on your laptop called `aws.cer`

## ssh into a CoreOS instance

Go to the AWS console under EC2 instances and find the public ip of one of your newly launched CoreOS instances.  

Choose any one of them (it doesn't matter which), and ssh into it as the **core** user with the cert provided in the previous step:

```
$ ssh -i aws.cer -A core@ec2-54-83-80-161.compute-1.amazonaws.com
```

## Sanity check
   
Let's make sure the CoreOS cluster is healthy first:

```
$ fleetctl list-machines
```

This should return a list of machines in the cluster, like this:

```
MACHINE	        IP              METADATA
03b08680...     10.33.185.16    -
209a8a2e...     10.164.175.9    -
25dd84b7...     10.13.180.194   -
```


## Launch cluster

```
$ sudo docker run --net=host tleyden5iwx/couchbase-cluster-go:0.4 couchbase-fleet launch-cbs --version 3.0.1 --num-nodes 3 --userpass "user:passw0rd" --docker-tag 0.4
```

Where:

* **--version** the version of Couchbase Server to use.  Valid values are 3.0.1 or 2.2.0.  (community edition in both cases)
* **--num-nodes** the total number of couchbase nodes to start -- should correspond to number of ec2 instances (eg, 3)
* **--userpass** the username and password as a single string, delimited by a colon (:) 
* **--docker-tag** the docker tag to use to launch containers

Replace `user:passw0rd` with a sensible username and password.  It **must** be colon separated, with no spaces.  The password itself must be at least 6 characters.

Once this command completes, your cluster will be up and running.

## Verify 

To check the status of your cluster, run:

```
$ fleetctl list-units
```

You should see three units, all as active.

```
UNIT                            MACHINE                         ACTIVE	SUB
couchbase_node@1.service        3c819355.../10.239.170.243      active	running
couchbase_node@2.service        782b35d4.../10.168.87.23        active	running
couchbase_node@3.service        7cd5f94c.../10.234.188.145      active	running
```

# Login to Admin Web UI

* Find the public ip of any of your CoreOS instances via the AWS console
* In a browser, go to `http://<instance_public_ip>:8091`
* Login with the username/password you provided above

You should see:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/couchbase_admin_ui_post_rebalance.png)

(Note: it may still be in the process of rebalancing, which is normal.  Go have a coffee and check back later)

Congratulations!  You now have a 3 node Couchbase Server cluster running under CoreOS / Docker.  

# References

* [Dockerfiles + Fleet init scripts](https://github.com/couchbaselabs/couchbase-server-docker)
* [How I built couchbase 2.2 for docker](https://gist.github.com/dustin/6605182) by [@dlsspy](https://twitter.com/dlsspy)
* https://registry.hub.docker.com/u/ncolomer/couchbase/
* https://github.com/lifegadget/docker-couchbase
