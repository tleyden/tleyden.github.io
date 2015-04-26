---
layout: post
title: "Starting a systemd service from Go"
date: 2015-01-17 09:48
comments: true
categories: golang, devops
---

I am working on a system for running Couchbase Server under CoreOS + Docker, and got to the point where I needed to start up a systemd service from a Go program.  I was about to use the [exec](http://golang.org/pkg/os/exec/) built-in package, but then thought to myself -- "isn't there a cleaner way"?

After some brief googling, I came across [coreos/go-systemd](http://godoc.org/github.com/coreos/go-systemd/), and figured I'd give it a shot.

## Connecting to DBUS

I'm still wrapping my head around systemd, but it looks like you talk to it through this thing called DBUS.  

I tried the naive approach:

```
import 	"github.com/coreos/go-systemd/dbus"

func (c CouchbaseCluster) StartCouchbaseService() error {

	dbusConnection, err := dbus.New()
	if err != nil {
		return err
	}

	log.Printf("dbusConnection: %v+", dbusConnection)
	return nil
}

```

and ran this as root on a CentOS6 box, but `dbus.New()` returned an error:

```
2015/01/17 07:38:14 dial unix /var/run/dbus/system_bus_socket: no such file or directory
```

Stuck .. https://groups.google.com/d/msg/coreos-user/tEzxXvEi-iE/JBtNREmqWpQJ


