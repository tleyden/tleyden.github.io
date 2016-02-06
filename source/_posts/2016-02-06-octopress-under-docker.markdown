---
layout: post
title: "Octopress under Docker"
date: 2016-02-06 05:38
comments: true
categories: octopress docker
---

I'm setting up a clean install of El Capitan, and want to get my Octopress blog going.  However, I don't want to install it *directly* on my OSX workstation -- I want to have it *contained* in a docker container.

## Install Docker

That's beyond the scope of this blog post, but what I ended up doing on my new OSX installation was to:

* Install VirtualBox 5.0.14
* Install [docker toolbox](https://www.docker.com/products/docker-toolbox) 

## Run tleyden5iwx/octopress

```
$ docker run -itd -v ~/Documents/blog/:/blog tleyden5iwx/octopress /bin/bash
```

What's in `~/Documents/blog/`?  Basically, the octopress instance I'd setup as described in [Octopress Setup Part I](http://tleyden.github.io/blog/2013/09/07/octopress-setup-part-i/).

## Bundle install

From inside the docker container:

```
# cd /blog/octopress
# bundle install
```

## Edit a blog post

On OSX, open up `~/Documents/blog/source/_posts/path-to-post` and make some minor edits

## Configure git

```
# git config --global user.name "YOUR NAME"
# git config --global user.email "YOUR EMAIL ADDRESS"
```

## Push source

```
# git push origin source
```

## Generate and push to master 

**Attempt 1**

```
# rake generate
rake aborted!
Gem::LoadError: You have already activated rake 10.4.2, but your Gemfile requires rake 0.9.6. Using bundle exec may solve this.
/blog/octopress/Rakefile:2:in `<top (required)>'
(See full trace by running task with --trace)	
```

I have no idea why this is happening, but I just conceded defeat against these ruby weirdisms, wished I was using Go (and thought about converting my blog to Hugo), and took their advice and prefixed every command thereafter with `bundle exec`.  

**Attempt 2**

```
# bundle exec rake generate && bundle exec rake deploy
Username for 'https://github.com': [enter your username]
Password for 'https://username@github.com': [enter your password]
```

Success! 


