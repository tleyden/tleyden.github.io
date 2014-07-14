---
layout: post
title: "Running Couchbase Sync Gateway on Google Compute Engine"
date: 2014-06-22 19:10
comments: true
categories: couchbase, mobile, google-compute-engine
---

First, a quick refresh of what Couchbase Sync Gateway actually *is*.  

So here's a birds-eye-view of the [Couchbase Mobile](http://developer.couchbase.com/mobile) architecture:

![diagram](https://camo.githubusercontent.com/c1aa705fde3eb12245c06730d850c23e5a84ad8d/687474703a2f2f746c657964656e2d6d6973632e73332e616d617a6f6e6177732e636f6d2f636f756368626173652d6c6974652f636f756368626173652d6c6974652d6172636869746563747572652e706e67)

Sync Gateway allows Couchbase Lite mobile apps to sync data between each other and the Couchbase Server running on the backend.

This blog post will walk you through how to run Sync Gateway in a Docker container on Google Compute Engine. 

## Create GCE instance and ssh in

Follow the instructions on [Running Docker on Google Compute Engine](http://docs.docker.com/installation/google/).

At this point you should be ssh'd into your GCE instance

## Create a configuration JSON

Here's a sample [example JSON configuration](https://gist.github.com/tleyden/d97d985eb1e0725e858e) for Sync Gateway which uses [walrus](https://github.com/couchbaselabs/walrus) as it's backing store, rather than Couchbase Server.  Later we will swap in Couchbase Server as a backing store.

## Run Sync Gateway docker container 

```
gce:~$ sudo docker run -d -name sg -p 4984:4984 -p 4985:4985 tleyden5iwx/couchbase-sync-gateway sync_gateway "https://gist.githubusercontent.com/tleyden/d97d985eb1e0725e858e/raw"
```

This will return a container id, eg `8ffb83fd1f`.

Check the logs to make sure there are no serious errors in the logs:

```
gce:~$ sudo docker logs 8ffb83fd1f
```

You should see something along the lines of:

```
02:23:58.905587 Enabling logging: [REST]
02:23:58.905818 ==== Couchbase Sync Gateway/1.00 (unofficial) ====
02:23:58.905863 Opening db /sync_gateway as bucket "sync_gateway", pool "default", server <walrus:/opt/sync_gateway/data>
02:23:58.905964 Opening Walrus database sync_gateway on <walrus:/opt/sync_gateway/data>
02:23:58.909659 Starting admin server on :4985
02:23:58.913260 Starting server on :4984 ...
```

## Expose API port 4984 via Firewall rule

On your workstation with the `gcloud` tool installed, run:

```
$ gcloud compute firewalls create sg-4984 --allow tcp:4984
```

## Verify that it's running

### Find out external ip address of instance

On your workstation with the `gcloud` tool installed, run:

```
$ gcloud compute instances list
name     status  zone          machineType internalIP   externalIP
couchbse RUNNING us-central1-a f1-micro    10.240.74.44 142.222.178.49
```
Your external ip is listed under the externalIP column, eg `142.222.178.49` in this example.


### Run curl request

On your workstation, replace the ip below with your own ip, and run:

```
$ curl http://142.222.178.49:4984
```

You should get a response like:

```
{"couchdb":"Welcome","vendor":{"name":"Couchbase Sync Gateway","version":1},"version":"Couchbase Sync Gateway/1.00 (unofficial)"}
```

## Re-run it with Couchbase Server backing store

*OK, so we've gotten it working with walrus.  But have you looked at the walrus website lately?  One [click](https://camo.githubusercontent.com/1bd1955b96628260b27320f099aeac0585229c2f/687474703a2f2f7777772e69686173616275636b65742e636f6d2f696d616765732f77616c7275735f6275636b65742e6a7067) and it's pretty obvious that this thing is not exactly meant to be a scalable production ready backend, nor has it ever claimed to be.*

Let's dump walrus for now and use Couchbase Server from this point onwards.

### Start Couchbase Server 

Before moving on, you will need to go through the instructions in [Running Couchbase Server on GCE](http://tleyden.github.io/blog/2014/06/22/running-couchbase-server-on-gce/) in order to get a Couchbase Server instance running.  

### Stop Sync Gateway

Run this command to stop the Sync Gateway container and completely remove it, using the same container id you used earlier:

```
gce:~$ sudo docker stop 8ffb83fd1f && sudo docker rm 8ffb83fd1f
```

### Update config

Copy this [example JSON configuration](https://gist.github.com/tleyden/c9e6396f7183c0f3e28c), which expects a Couchbase Server running on `http://172.17.0.2:8091`, and update it with the ip address of the docker instance where your Couchbase Server is running.  To get this ip address, follow the [these instructions](http://tleyden.github.io/blog/2014/06/22/running-couchbase-server-on-gce/) in the "Find the Docker instance IP address" section.

Now upload your modified JSON configuration to a website that is publicly accessible, for example in a [Github Gist](http://gist.github.com).  

### Run Sync Gateway

Run Sync Gateway again, this time using Couchbase Server as a backing store this time.

Replace `http://yourserver.co/yourconfig.json` with the URL where you've uploaded your JSON configuration from the previous step.  

```
gce:~$ sudo docker run -d -name sg -p 4984:4984 -p 4985:4985 tleyden5iwx/couchbase-sync-gateway sync_gateway "http://yourserver.co/yourconfig.json"
```

This will return a container id, eg `9ffb83fd1f`.  Again, check the logs to make sure there are no serious errors in the logs:

```
gce:~$ sudo docker logs 9ffb83fd1f
```

You should see something along the lines of:

```
... 
02:23:58.913260 Starting server on :4984 ...
```

with no errors.

## Verify it's working

### Save a document via curl

The easiest way to add a document is via the Admin port, since there is no authentication to worry about.  Since we haven't added a firewall rule to expose the admin port (4985), (and doing so without tight filtering would be a major security hole), the following command to create a new document must be run on the GCE instance.

```
gce:~$ curl -H "Content-Type: application/json" -d '{"such":"json"}' http://localhost:4985/sync_gateway/
```

If it worked, you should see a response like:

```
{"id":"3cbfbe43e76b7eb5c4c221a78b2cf0cc","ok":true,"rev":"1-cd809becc169215072fd567eebd8b8de"}
```

### View document on Couchbase Server

To verify the document was successfully stored on Couchbase Server, you'll need to login to the Couchbase Server Web Admin UI.  There are instructions [here](http://tleyden.github.io/blog/2014/06/22/running-couchbase-server-on-gce/) on how to do that.

From there, navigate to Data Buckets / default / Documents, and you should see:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/couchbase_server_docs.png)

Click on the document that has a UUID (eg, "29f8d7.." in the screenshot above), and you should see the document's contents:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/couchbase_server_doc.png)

The `_sync` metadata field is used internally by the Sync Gateway and can be ignored.  The actual doc contents are towards the end of the file: `.."such":"json"}`



