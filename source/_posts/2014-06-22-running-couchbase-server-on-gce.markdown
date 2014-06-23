---
layout: post
title: "Running a Couchbase Cluster on Google Compute Engine"
date: 2014-06-22 15:52
comments: true
categories: 
---

The easiest way to run Couchbase cluster on Google Compute Engine is to run all of the nodes in Docker containers.

## Create GCE instance and ssh in

Follow the instructions on [Running Docker on Google Compute Engine](http://docs.docker.com/installation/google/).

At this point you should be ssh'd into your GCE instance

## Start Couchbase Server

```
gce:~$ sudo docker run -d -name cb1 -p 8091:8091 -p 8092:8092 -p 11210:11210 -p 11211:11211 ncolomer/couchbase
```

## Verify it's running

### Find the Docker instance IP address

On the GCE instance, run:

```
{% raw  %}gce:~$ sudo docker inspect -format '{{ .NetworkSettings.IPAddress }}' cb1{% endraw %}
```

This should return an ip address, eg `172.17.0.2`

Set it as an environment variable so we can use it in later steps:

```
gce:~$ export CB1_IP=172.17.0.2
```

### Run couchbase-cli

To verify that couchbase server is running, use the `couchbase-cli` to ask for server info:

```
gce:~$ sudo docker run -rm ncolomer/couchbase couchbase-cli server-info -c ${CB1_IP} -u Administrator -p couchbase
```

If everything is working correctly, this should return a json response, eg:

```
{
  "availableStorage": {
    "hdd": [
      {
        "path": "/",
  ...
}
```

## Start a 3-node cluster

On the GCE instance, run the following commands:

```
gce:~$ sudo docker run -d -name cb2 ncolomer/couchbase couchbase-start ${CB1_IP}
gce:~$ sudo docker run -d -name cb3 ncolomer/couchbase couchbase-start ${CB1_IP}
```

The nodes `cb2` and `cb3` will automatically join the cluster via `cb1`. The cluster needs a rebalance to be fully operational. To do so, run the following command:

```
gce:~$ sudo docker run -rm ncolomer/couchbase couchbase-cli rebalance -c ${CB1_IP} -u Administrator -p couchbase
```

## Connect to admin web UI

The easiest way to manage a Couchbase Server cluster is via the built-in Web Admin UI.

In order to access it, we will need to make some network changes.

### Expose port 8091 via firewall rule for your machine

Go to [whatismyip.com](http://www.whatismyip.com/) or equivalent, and find your ip address.  Eg, `67.161.66.7`

On your workstation with the `gcloud` tool installed, run:

```
$ gcloud compute firewalls create cb-8091 --allow tcp:8091 --source-ranges 67.161.66.7/32
```

This will allow your machine, as well any other machine behind your internet router, to connect to the Couchbase Web UI running on GCE.

To increase security, you should use ipv6 and pass your workstation's ipv6 hostname in the `--source-ranges` parameter.

### Find out external ip address of instance

On your workstation with the `gcloud` tool installed, run:

```
$ gcloud compute instances list
name     status  zone          machineType internalIP   externalIP
couchbse RUNNING us-central1-a f1-micro    10.240.74.44 142.222.178.49
```
Your external ip is listed under the externalIP column, eg `142.222.178.49` in this example.

### Go to admin in web browser

Go to http://142.222.178.49:8091 into your web browser (replacing w/ your external ip)

You should see a screen like this:

![screenshot](http://cl.ly/image/2m1i01192U0G/Screen%20Shot%202014-06-22%20at%207.07.36%20PM.png)

Default credentials:

* Username: Administrator
* Password: couchbase

## Known issues

* [File descriptor warning in logs](http://stackoverflow.com/questions/24356815/running-couchbase-under-gce-docker-and-getting-error-about-max-number-of-files)

## References

* [ncolomer/couchbase Docker instructions](https://registry.hub.docker.com/u/ncolomer/couchbase/)