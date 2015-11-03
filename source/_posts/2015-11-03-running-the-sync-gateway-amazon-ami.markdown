---
layout: post
title: "Running the Sync Gateway Amazon AMI"
date: 2015-11-03 11:11
comments: true
categories: couchbase, aws
---

How to run the Couchbase Sync Gateway AWS AMI

## Kick off AWS instance

* Browse to the [Sync Gateway AMI](https://aws.amazon.com/marketplace/pp/B013XDO1B4) in the AWS Marketplace
* Click Continue
* Change all ports to "MY IP" except for port 4984
* Make sure you choose a key that you have locally

## SSH in and start Sync Gateway

* Go to the AWS console, find the EC2 instance, and find the instance public ip address.  It should look like this: `ec2-54-161-201-224.compute-1.amazonaws.com`.  The rest of the instructions will refer to this as <instance public ip>
* `ssh ec2-user@<instance public ip>` (this should let you in without prompting you for a password.  if not, you chose a key when you launched that you don't have locally)
* Start the Sync Gateway with this command:

```
/opt/couchbase-sync-gateway/bin/sync_gateway -interface=0.0.0.0:4984 -url=http://localhost:8091 -bucket=sync_gateway -dbname=sync_gateway
```
* You should see output like this:

```
2015-11-03T19:37:05.384Z ==== Couchbase Sync Gateway/1.1.0(28;86f028c) ====
2015-11-03T19:37:05.384Z Opening db /sync_gateway as bucket "sync_gateway", pool "default", server <http://localhost:8091>
2015-11-03T19:37:05.384Z Opening Couchbase database sync_gateway on <http://localhost:8091>
2015/11/03 19:37:05  Trying with selected node 0
2015/11/03 19:37:05  Trying with selected node 0
2015-11-03T19:37:05.536Z Using default sync function 'channel(doc.channels)' for database "sync_gateway"
2015-11-03T19:37:05.536Z     Reset guest user to config
2015-11-03T19:37:05.536Z Starting profile server on
2015-11-03T19:37:05.536Z Starting admin server on 127.0.0.1:4985
2015-11-03T19:37:05.550Z Starting server on localhost:4984 ...
```

## Verify via curl

From your workstation:

```
$ curl http://<instance public ip>:4984/sync_gateway/
```

You should get a response like:

```
{"committed_update_seq":1,"compact_running":false,"db_name":"sync_gateway","disk_format_version":0,"instance_start_time":1446579479331843,"purge_seq":0,"update_seq":1}
```

## Customize configuration

For more advanced Sync Gateway configuration, you will want to create a JSON config file on the EC2 instance itself and pass that to Sync Gateway when you launch it, or host your config JSON on the internet somewhere and pass Sync Gateway the URL to the file.

## View Couchbase Server UI

In order to login to the Couchbase Server UI, go to <instance public ip>:8091 and use:

* **Username:** Administrator
* **Password:** `<aws instance id, eg: i-8a9f8335>`
