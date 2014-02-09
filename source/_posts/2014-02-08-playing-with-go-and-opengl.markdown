---
layout: post
title: "Playing with Go and OpenGL"
date: 2014-02-08 16:01
comments: true
categories: golang
---

Get this spinning gopher working with Go and OpenGL on OSX Mavericks via [gogl](https://github.com/chsc/gogl/)

<iframe width="420" height="315" src="//www.youtube.com/embed/yae-bRLdfaU" frameborder="0" allowfullscreen></iframe>

# Steps

```
$ brew install glfw2
$ go get -u -v github.com/tleyden/gogl
$ go get -u -v github.com/go-gl/glfw  
$ cd $GOPATH/src/github.com/tleyden/gogl
$ make bindings
$ go get -u -v github.com/chsc/gogl
$ cd $GOPATH/src/github.com/tleyden/gogl/examples/gopher
$ go run gopher.go
```

NOTE: if [pull request #37](https://github.com/chsc/gogl/pull/37) has already been merged into [gogl](https://github.com/chsc/gogl/), then replace `github.com/tleyden/gogl` with `https://github.com/chsc/gogl` in steps above.

