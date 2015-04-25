---
layout: post
title: "Setting up Octopress under Docker"
date: 2015-04-25 03:57
comments: true
categories: docker octopress
---

I got a new computer last week.  It's the latest macbook retina, and I needed to refresh because I wanted a bigger SSD drive (and after having an SSD drive, I'll never go back)

Anyway, I'm trying to get my Octopress blog going again, and oh my God, what a nightmare.  Octopress was working beautifully for me for years, and then all of the sudden I am at the edge of Ruby Dependency Hell staring at an Octopress giving me eight fingers.

With the help of Docker, I've managed to tame this eight legged beast, barely.

## Run Docker

If you're on Linux, it's as easy as `apt-get install docker` or `yum install docker`.

If you're on OSX, I wrote a [blog post](http://tleyden.github.io/blog/2013/11/12/docker-on-osx/) on how to do this, which is probably way out of date, but at least will point you in the right direction.

## Install Octopress Docker image

```
$ docker run -ti tleyden5iwx/octopress /bin/bash
```




