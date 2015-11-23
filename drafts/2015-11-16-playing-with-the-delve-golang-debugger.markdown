---
layout: post
title: "Playing with the Delve Golang debugger"
date: 2015-11-16 15:41
comments: true
categories: golang
---

## Go get

```
$ go get github.com/derekparker/delve/...
```

Ignore this error:

```
go build github.com/derekparker/delve/service/test: no buildable Go source files in /Users/tleyden/Development/gocode/src/github.com/derekparker/delve/service/test
```

## Create Cert (OSX only)

Follow [these instructions](https://github.com/derekparker/delve/wiki/Building#1-create-the-cert)

## Build 

```
$ cd 
$ CERT=dlv-cert make install
```

At this point, you should have the `dlv` binary installed on your path.

## Debug 

In this example, I'm going to debug [Couchbase Sync Gateway](https://github.com/couchbase/sync_gateway).  

```
$ dlv exec bin/sync_gateway -- config.json
```
