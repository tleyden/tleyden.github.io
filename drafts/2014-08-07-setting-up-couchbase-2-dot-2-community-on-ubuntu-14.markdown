---
layout: post
title: "Setting up Couchbase 2.2 Community on Ubuntu 14"
date: 2014-08-07 10:56
comments: true
categories: couchbase
---


## Install via .deb package

On each machine in your cluster, do the following:

```
$ sudo apt-get install libssl0.9.8
$ wget http://packages.couchbase.com/releases/2.2.0/couchbase-server-community_2.2.0_x86_64.deb
$ sudo dpkg -i couchbase-server-community_2.2.0_x86_64.deb

```

You should see a message:

```
...
You have successfully installed Couchbase Server.
...
```

## Configure via web admin

* Choose an arbitrary machine in your cluster to connect to
* In your browser, go to http://<server_ip>:8091/index.html



## Reference

[Official Docs](http://docs.couchbase.com/couchbase-manual-2.2/#installing-and-upgrading)