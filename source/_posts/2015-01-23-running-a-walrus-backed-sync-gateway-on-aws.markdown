---
layout: post
title: "Running a Walrus-backed Sync Gateway on AWS"
date: 2015-01-23 09:30
comments: true
categories: sync-gateway, couchbase
---

Follow the steps below to create a Sync Gateway instance running under AWS with the following architecture:

![architecture diagram](http://tleyden-misc.s3.amazonaws.com/blog_images/sync_gw_walrus_aws.png)

It will be using the [Walrus](https://github.com/couchbaselabs/walrus) in-memory database, and so it is only useful for light testing.  Walrus does have the abiity to snapshot its memory contents to a file, so your data can persist across restarts.

**Warning: don't run this in production!**  If you want something that is closer to production ready, check out [Running a Sync Gateway Cluster Under CoreOS on AWS](http://tleyden.github.io/blog/2014/12/15/running-a-sync-gateway-cluster-under-coreos-on-aws/) instead.

## Launch EC2 instance

Go to the [Cloudformation Wizard](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#cstack=sn%7ECouchbase-CoreOS%7Cturl%7Ehttp://tleyden-misc.s3.amazonaws.com/couchbase-coreos/sync_gateway.template) 

Recommended values:

* **ClusterSize**: 1 node 
* **Discovery URL**:  as it says, you need to grab a new token from https://discovery.etcd.io/new and paste it in the box.
* **KeyPair**: the name of the AWS keypair you want to use.

For the keypair that you use, your local ssh client will need to have the private key side of that keypair.  

### Wait until instances are up

Hit the "reload" button until it goes to the CREATE_COMPLETE state.

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/cloud-formation-create-complete.png)

## Find ip of instance

Go to the AWS console under the "EC2 instances" section and find the public ip of one of your newly launched CoreOS instances.

Choose any one of them (it doesn't matter which), and look for the **Public IP**.  Copy that value onto your clipboard.

### SSH into instance

ssh into it as the **core** user with the cert provided in the previous step:

```
$ ssh -A core@ec2-54-83-80-161.compute-1.amazonaws.com
```

## Create a volume directory

After you ssh into your instance, create a volume directory so that the data persists across different container instances.

```
$ sudo mkdir -p /opt/sync_gateway/data
$ sudo chown -R core:core /opt/sync_gateway/data
```

## Launch Sync Gateway

```
$ SYNC_GW_CONFIG=https://gist.githubusercontent.com/tleyden/368f01218baf4e760267/raw/a65be036bc3855d5ab4e73b849f4caa1dc7d390f/config.json
$ sudo docker run -d --name sync_gw --net=host -v /opt/sync_gateway/data:/opt/sync_gateway/data tleyden5iwx/sync-gateway-coreos sync-gw-start -c master -g $SYNC_GW_CONFIG
```

You should see the following output:

```
Unable to find image 'tleyden5iwx/sync-gateway-coreos' locally
Pulling repository tleyden5iwx/sync-gateway-coreos
daa0c81d9745: Download complete
......
Status: Downloaded newer image for tleyden5iwx/sync-gateway-coreos:latest
d22035060882a2071c3e0a556ae5db5041f84e3004d67fb11355b6d8a7bf40b8
$ 
```

Congratulations!  You now have a Sync Gateway running.  

It might feel underwhelming, because nothing appears to be happening, but sync gateway is actually running in the background.  To verify that, run:

```
$ sudo docker ps
CONTAINER ID        IMAGE                                    COMMAND                CREATED              STATUS              PORTS               NAMES
d22035060882        tleyden5iwx/sync-gateway-coreos:latest   "sync-gw-start -c ma   About a minute ago   Up About a minute                       sync_gw
```

## View logs

```
$ CONTAINER_ID=$(sudo docker ps | grep -iv container | awk '{ print $1 }')
$ sudo docker logs --follow ${CONTAINER_ID}
```

## Verify Sync Gateway

Assuming your public ip is `54.81.228.221`, paste `http://54.81.228.221:4984` into your web browser and you should see:

```
{
    "couchdb":"Welcome",
    "vendor":{
        "name":"Couchbase Sync Gateway",
        "version":1
    },
    "version":"Couchbase Sync Gateway/master(6356065)"
}
```

To make sure the database was configured correctly, change the url to `http://54.81.228.221:4984/db`, and you should see:

```
{
    "db_name":"db",
    .. etc ..
}
```

## Try out document API via curl

**Create a new document**

```
$ curl -H 'Content-Type: application/json' -X POST -d '{"hello":"sync gateway"}' http://54.81.228.221:4984/db/
```

This will return the following JSON:

```
{
    "id":"f1c8c5f8de22a09544b97fcc20fce316",
    "ok":true,
    "rev":"1-016b8855d6faf2d703a8b35a44cd4a40"
}
```

**View the document**

Using the doc id returned above:

```
$ curl http://54.81.228.221:4984/db/f1c8c5f8de22a09544b97fcc20fce316
```

You should see:

```
{
    "_id":"f1c8c5f8de22a09544b97fcc20fce316",
    "_rev":"1-016b8855d6faf2d703a8b35a44cd4a40",
    "hello":"sync gateway"
}
```

Check out the [Sync Gateway REST API docs](http://developer.couchbase.com/mobile/develop/references/sync-gateway/rest-api/index.html) for full documentation on the available REST calls you can make.

## Restart Sync Gateway with new config

If you need to change your sync gateway config, follow the instructions below.

**Stop and remove existing container**

Find the container id via `sudo docker ps` as shown above, and run this command with your own container id:

```
$ CONTAINER_ID=$(sudo docker ps | grep -iv container | awk '{ print $1 }')
$ sudo docker stop ${CONTAINER_ID} && sudo docker rm ${CONTAINER_ID}
```

**Update sync gateway config**

You can take this [sample config](https://gist.githubusercontent.com/tleyden/368f01218baf4e760267/raw/a65be036bc3855d5ab4e73b849f4caa1dc7d390f/config.json) and customize it to your needs, and then upload it somewhere on the web.  

Make sure you keep the `server` field as `"walrus:data"`, since that tells Sync Gateway to use walrus and to store the data in the `/opt/sync_gateway/data` directory.

**Start container with new config**
 
```
$ SYNC_GW_CONFIG=https://yourserver.com/yourconfig.json
$ sudo docker run --name sync_gw --net=host -v /opt/sync_gateway/data:/opt/sync_gateway/data tleyden5iwx/sync-gateway-coreos sync-gw-start -c master -g $SYNC_GW_CONFIG
```

After it starts up, your sync gateway will be running with the new config.

## Next step: try out the GrocerySync app

Choose the GrocerySync app for your platform:

* [GrocerySync-Android](https://github.com/couchbaselabs/GrocerySync-Android)
* [GrocerySync-iOS](https://github.com/couchbaselabs/Grocery-Sync-iOS)
* [GrocerySync-DotNet](https://github.com/couchbase/couchbase-lite-net/tree/master/samples)

and point the sync url at your server instead of the default.  Now should be able to sync data through your own Sync Gateway.

If you are on Phonegap, check our [sample apps](http://developer.couchbase.com/mobile/develop/samples/samples/index.html) listing which has a link to the TodoLite-Phonegap app.