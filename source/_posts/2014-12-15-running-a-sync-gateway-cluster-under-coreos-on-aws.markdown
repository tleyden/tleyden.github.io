---
layout: post
title: "Running a Sync Gateway Cluster Under CoreOS on AWS"
date: 2014-12-15 19:22
comments: true
categories: couchbase-mobile sync-gateway coreos aws
---

Follow the steps below to create a Sync Gateway + Couchbase Server cluster running under AWS with the following architecture:

![architecture diagram](http://tleyden-misc.s3.amazonaws.com/blog_images/sync-gw-coreos-onion.png)

*Disclaimer: this approach to running Couchbase Server and Sync Gateway is entirely **experimental** and you should do your own testing before running a production system.  Having said that, this approach has undergone a [major feedback loop](https://github.com/couchbaselabs/couchbase-server-docker/issues/2) from real users, and this version is a lot more stable than the initial version.*

## Kick off Couchbase Server + Sync Gateway cluster

### Launch EC2 instances

[<img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png">](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#cstack=sn%7ECouchbase-CoreOS%7Cturl%7Ehttp://tleyden-misc.s3.amazonaws.com/couchbase-coreos/sync_gateway.template)

Recommended values:

* **ClusterSize**: 3 nodes (default)
* **Discovery URL**:  as it says, you need to grab a new token from https://discovery.etcd.io/new and paste it in the box.
* **KeyPair**: the name of the AWS keypair you want to use.  If you haven't already, you'll want to upload your local ssh key into AWS and create a named keypair.

### Wait until instances are up

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/cloud-formation-create-complete.png)

### ssh into a CoreOS instance

Go to the AWS console under EC2 instances and find the public ip of one of your newly launched CoreOS instances.

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/ec2-instances-coreos.png)  

Choose any one of them (it doesn't matter which), and ssh into it as the **core** user with the cert provided in the previous step:

```
$ ssh -i aws.cer -A core@ec2-54-83-80-161.compute-1.amazonaws.com
```

### Kick off Couchbase Server cluster

```
$ sudo docker run --net=host tleyden5iwx/couchbase-cluster-go:0.8.5 couchbase-fleet launch-cbs --version latest --num-nodes 3 --userpass "user:passw0rd" --docker-tag 0.8.5
```

Where:

* --version=<cb-version> Couchbase Server version -- see [Docker Tags](https://registry.hub.docker.com/u/couchbase/server/tags/manage/) for a list of versions that can be used.
* --num-nodes=<num_nodes> number of couchbase nodes to start
* --userpass <user:pass> the username and password as a single string, delimited by a colon (:)
* --etcd-servers=<server-list>  Comma separated list of etcd servers, or omit to connect to etcd running on localhost
* --docker-tag=<docker-tag>  if present, use this docker tag for spawned containers, otherwise, default to "latest"

Replace `user:passw0rd` with a sensible username and password.  It **must** be colon separated, with no spaces.  The password itself must be at least 6 characters.

The output should look something like [this gist](https://gist.github.com/tleyden/bc0975778216281b80e7).

### Kick off Sync Gateway cluster 

```
$ sudo docker run --net=host tleyden5iwx/couchbase-cluster-go:0.8.5 sync-gw-cluster launch-sgw --num-nodes=1 --config-url=http://git.io/b9PK --create-bucket todos --create-bucket-size 512 --create-bucket-replicas 1 --docker-tag 0.8.5
```

Where:

* --num-nodes=<num_nodes> number of sync gw nodes to start
* --config-url=<config_url> the url where the sync gw config json is stored
* --sync-gw-commit=<branch-or-commit> the branch or commit of sync gw to use, defaults to "image", which is the master branch at the time the docker image was built.
* --create-bucket=<bucket-name> create a bucket on couchbase server with the given name 
* --create-bucket-size=<bucket-size-mb> if creating a bucket, use this size in MB
* --create-bucket-replicas=<replica-count> if creating a bucket, use this replica count (defaults to 1)
* --etcd-servers=<server-list>  Comma separated list of etcd servers, or omit to connect to etcd running on localhost
* --docker-tag=<docker-tag>  if present, use this docker tag for spawned containers, otherwise, default to "latest"


### View cluster

After the above script finishes, run `fleetctl list-units` to list the services in your cluster, and you should see:

```
UNIT                            MACHINE                         ACTIVE  SUB
couchbase_node@1.service        2ad1cfaf.../10.95.196.213       active  running
couchbase_node@2.service        a688ca8e.../10.216.199.207      active  running
couchbase_node@3.service        fb241f71.../10.153.232.237      active  running
sync_gw_node@1.service          2ad1cfaf.../10.95.196.213       active  running
```

They should all be in the `active` state.  If any are in the `activating` state -- which is normal because it might take some time to download the docker image -- then you should wait until they are all active before continuing.

## Verify internal

**Find internal ip**

```
$ fleetctl list-units
sync_gw_node.1.service				209a8a2e.../10.164.175.9	active	running
```

**Curl**

On the CoreOS instance you are already ssh'd into, Use the ip found above and run a curl request against the server root:

```
$ curl 10.164.175.9:4984
{"couchdb":"Welcome","vendor":{"name":"Couchbase Sync Gateway","version":1},"version":"Couchbase Sync Gateway/master(6356065)"}
```

## Verify external

**Find external ip**

Using the internal ip found above, go to the EC2 Instances section of the AWS console, and hunt around until you find the instance with that internal ip, and then get the public ip for that instance, eg: `ec2-54-211-206-18.compute-1.amazonaws.com`

**Curl**

From your laptop, use the ip found above and run a curl request against the server root:

```
$ curl ec2-54-211-206-18.compute-1.amazonaws.com:4984
{"couchdb":"Welcome","vendor":{"name":"Couchbase Sync Gateway","version":1},"version":"Couchbase Sync Gateway/master(6356065)"}
```

Congratulations!  You now have a Couchbase Server + Sync Gateway cluster running.

## Appendix A: Kicking off more Sync Gateway nodes.

To launch two more Sync Gateway nodes, run the following command:

```
$ sudo docker run --net=host tleyden5iwx/couchbase-cluster-go:0.8.5 sync-gw-cluster launch-sgw --num-nodes=2 --config-url=http://git.io/b9PK --docker-tag 0.8.5
```

## Appendix B: Setting up Elastic Load Balancer.

*Warning: Users have been having [problems](https://groups.google.com/d/msg/mobile-couchbase/jJMqnoauMWQ/FHND_WqtYaMJ) getting WebSockets to work behind ELB, as well as [connection timeouts](https://groups.google.com/d/msg/mobile-couchbase/oxeSlYS2-Aw/gw4UcA89KlsJ).  Unless you are planning to disable websocket support for iOS clients, you should use [nginx as described here](http://developer.couchbase.com/mobile/develop/guides/sync-gateway/nginx/index.html) rather than ELB.*

Setup an Elastic Load Balancer with the following settings:

![elb screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/sync_gateway_coreos_elb.png)

Note that it forwards to **port 4984**.

Once the Load Balancer has been created, go to its configuration to get its DNS name:

![elb screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/sync_gateway_coreos_elb2.png)

Now you should be able to run curl against that:

```
$ curl http://coreos-322270867.us-east-1.elb.amazonaws.com/
{"couchdb":"Welcome","vendor":{"name":"Couchbase Sync Gateway","version":1},"version":"Couchbase Sync Gateway/master(b47aee8)"}
```

## Appendix C: Verify with a sample app

Try running either of the following sample apps:

* [GrocerySync-Android](https://github.com/couchbaselabs/GrocerySync-Android) 
* [GrocerySync-iOS](https://github.com/couchbaselabs/Grocery-Sync-iOS) 

and pointing the Sync Gateway URL to your own Sync Gateway instance.  

## Appendix D: Shutting down the cluster.

Warning: if you try to shutdown the individual ec2 instances, **you must use the CloudFormation console**.  If you try to shutdown the instances via the EC2 control panel, AWS will restart them, because that is what the CloudFormation is telling it to do.

Here is the web UI where you need to shutdown the cluster:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/shutdown_cluster.png)

## Appendix E: Disabling CoreOS auto-restarts

CoreOS automatically restart nodes when security updates are available.  Initially, this caused [major problems](https://github.com/couchbaselabs/couchbase-server-docker/issues/2) with the way Couchbase Server was being spawned by the scripts used in this blog post.  Those issues are now fixed, but it's always possible new issues might arise.

To play it safe, if you want to prevent CoreOS from restarting itself:

* Shut down your existing cluster via CloudFormation (if you have data already, then please post a comment to this blog post asking for help)
* Make a copy of the [default CloudFormation template](http://tleyden-misc.s3.amazonaws.com/couchbase-coreos/sync_gateway.template) and save it on an S3 bucket.
* Change the `reboot-strategy` to `off`.  Here is an [example cloudformation template](http://tleyden-misc.s3.amazonaws.com/couchbase-coreos/sync_gateway_noreboot.template) with rebooting disabled.  See also: [CoreOS update strategies document](https://coreos.com/docs/cluster-management/setup/update-strategies/).  After you've made your changes, upload the edited version to S3.
* Kick off a new cluster from the Go to the [Cloudformation Wizard](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#cstack=sn%7ECouchbase-CoreOS%7Cturl%7Ehttp://tleyden-misc.s3.amazonaws.com/couchbase-coreos/sync_gateway.template), but change the value under `Specify an Amazon S3 template URL` to use your own template stored on S3 rather than the default.

But be warned, this is a less secure approach to running CoreOS.  

## References

* [sync gateway Docker + CoreOS fleet files](https://github.com/tleyden/sync-gateway-coreos)
* [couchbase-server-coreos](https://github.com/tleyden/couchbase-server-coreos)
* [Sync Gateway docs regarding reverse proxies](http://developer.couchbase.com/mobile/develop/guides/sync-gateway/nginx/index.html)
* [Couchbase Mobile Google Group discussion on ELB](https://groups.google.com/forum/?utm_medium=email&utm_source=footer#!msg/mobile-couchbase/pXKQIAiCaW8/s9W_gSfRL50J)
* [sync gateway](https://github.com/couchbase/sync_gateway)
* [andrewwebber/couchbase-array](https://github.com/andrewwebber/couchbase-array)
