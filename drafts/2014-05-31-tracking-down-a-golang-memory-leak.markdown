---
layout: post
title: "Tracking down a golang memory leak"
date: 2014-05-31 14:49
comments: true
categories: golang
---

## Install graphviz

pprof uses graphviz to render the graphs which show memory usage, so install graphviz if you don't already have it:

```
$ brew install graphviz
```

## Enable pprof

Add these imports

```
import _ "net/http/pprof"
import "net/htt"
import "log"
```

Add the following code to your main() function.  (assumes you aren't already running a webserver)

```
go func() {
   log.Println(http.ListenAndServe("localhost:6060", nil))
}()
```

## View heap profile

```
$ go tool pprof http://localhost:6060/debug/pprof/heap
```


