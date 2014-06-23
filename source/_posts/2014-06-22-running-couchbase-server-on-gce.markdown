---
layout: post
title: "Running Couchbase Server on GCE"
date: 2014-06-22 15:52
comments: true
categories: 
---

The easiest way to run Couchbase Server on Google Compute Engine is to run it in a Docker container.

The following instructions walk you through running a single node.  In a later blog post, I'll cover running a cluster.

## Create GCE instance and ssh in

Follow the instructions on [Running Docker on Google Compute Engine](http://docs.docker.com/installation/google/).

At this point you should be ssh'd into your GCE instance

## Start Couchbase Server

```
gce:~$ sudo docker run -d -name cb -p 8091:8091 -p 8092:8092 -p 11210:11210 -p 11211:11211 ncolomer/couchbase
```

## Verify it's running

### Find the Docker instance IP address

On the GCE instance, run:

```
gce:~$ sudo docker inspect -format '{{ .NetworkSettings.IPAddress }}' cb
```

This should return an ip address, eg:

```
172.17.0.2
```

### Run couchbase-cli

Using the ip address found in the step above:

```
gce:~$ sudo docker run -rm ncolomer/couchbase couchbase-cli server-info -c 172.17.0.2 -u Administrator -p couchbase
```

This should return a json response, eg:

```
{
  "availableStorage": {
    "hdd": [
      {
        "path": "/",
  ...
}
```

## Connect to admin web UI

### Expose port 8091 via Firewall rule

On your workstation with the `gcloud` tool installed, run:

```
$ gcloud compute firewalls create cb-8091 --allow tcp:8091
```

### Find out external ip address of instance

On your workstation with the `gcloud` tool installed, run:

```
$ gcloud compute instances list -l
name     status  zone          machineType internalIP   externalIP
couchbse RUNNING us-central1-a f1-micro    10.240.74.44 142.222.178.49
```
Your external ip is listed under the externalIP column, eg `142.222.178.49` in this example.

### Go to admin in web browser

Go to http://142.222.178.49:8091 into your web browser (replacing w/ your external ip)

Default credentials:

* Username: Administrator
* Password: couchbase

At this point, you should either change the default password, or delete the firewall rule added above.

## Known issues

* [File descriptor warning in logs](http://stackoverflow.com/questions/24356815/running-couchbase-under-gce-docker-and-getting-error-about-max-number-of-files)