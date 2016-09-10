---
layout: post
title: "Creating multiple Sync Gateway 1.3 installations on AWS"
date: 2016-06-23 20:24
comments: true
categories: couchbase
---

In this blog post I am going to do the following:

* Two Couchbase Server + Sync Gateway EC2 instances: one in AWS us-west and one in us-east
* Configure OpenID Connect
* Configure replication between the two Sync Gateway instances


## Launch AMIs

Note: these are pre-release AMI's for Sync Gateway version 1.3

* us-east: ami-45915c28
* us-west: ami-8e7f3bee

Follow [these instructions](https://github.com/couchbase/build/blob/master/scripts/jenkins/mobile/ami/README-ENDUSER.md#quickstart) for launching the instances.

## Open up port 4985

* ssh into both instances
* change `/opt/sync_gateway/etc/sync_gateway.json` config to:

```
{
  "adminInterface":":4985",
  "log": ["*"],
  "databases": {
    "db": {
      "server": "http://localhost:8091",
      "bucket": "default",
      "users": { "GUEST": { "disabled": false, "admin_channels": ["*"] } }
    }
  }
}
```
* Restart Sync Gateway via: `service sync_gateway restart`

## Update configuration for OpenID Connect

## Update configuration for replication





