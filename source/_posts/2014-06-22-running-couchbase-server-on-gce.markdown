---
layout: post
title: "Running Couchbase Server on GCE"
date: 2014-06-22 15:52
comments: true
categories: 
---

The easiest way to run Couchbase Server on Google Compute Engine is to run it in a Docker container.

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
gce:~$ sudo docker inspect -format '{{ .NetworkSettings.IPAddress }}' cb1
```

This should return an ip address, eg:

```
172.17.0.2
```

Set it as an environment variable so we can use it in later steps:

```
gce:~$ export CB1_IP=172.17.0.2
```

### Run couchbase-cli

To verify that couchbase server is running, use the `couchbase-cli` to ask for server info:

```
gce:~$ sudo docker run -rm ncolomer/couchbase couchbase-cli server-info -c ${CB1_IP} -u Administrator -p couchbase
```

If everything is working correclty, this should return a json response, eg:

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

## References

* [ncolomer/couchbase Docker instructions](https://registry.hub.docker.com/u/ncolomer/couchbase/)