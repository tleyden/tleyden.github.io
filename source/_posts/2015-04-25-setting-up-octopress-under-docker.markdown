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

This blog assumes you **already have an Octopress git repo**.  If you are starting from scratch, then check out [Octopress Setup Part I](http://tleyden.github.io/blog/2013/09/07/octopress-setup-part-i/)

## Install Octopress Docker image

```
$ docker run -ti tleyden5iwx/octopress /bin/bash
```

After this point, you'll be inside the Docker Container (Ubuntu 14).

## Delete Octopress dir + clone your Octopress repo

From within the container:

```
$ cd /root
$ rm -rf octopress/
$ git clone https://github.com/your-github-username/your-github-username.github.io.git octopress
$ cd octopress/
```

Now, switch to the source branch (which contains the content)

```
$ git checkout source
```

Re-install dependencies:

```
$ bundle install
```

Prevent ASCII encoding errors:

```
$ export LC_ALL=C.UTF-8
```

**Clone deploy directory**

```
$ git clone https://github.com/your-github-username/your-github-username.github.io.git _deploy
```

## Rake preview

As a smoke test, run:

```
$ bundle exec rake preview
```

If this gives no errors, that's a good sign.

## Create a new blog post

```
$ bundle exec rake new_post["Setting up Octopress under Docker"]
```

## Push to Source branch

```
$ git push origin source
```

## Deploy to Master branch

```
$ bundle exec rake generate && bundle exec rake deploy
```

After the above command, the changes should be visible on your github pages blog (eg, your-username.github.io)



