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

See [Installing Docker](https://docs.docker.com/installation/) for instructions.

This blog post assumes you **already have an Octopress git repo**.  If you are starting from scratch, then check out [Octopress Setup Part I](http://tleyden.github.io/blog/2013/09/07/octopress-setup-part-i/) to become even more confused. 

## Install Octopress Docker image

```
$ docker run -ti tleyden5iwx/octopress /bin/bash
```

After this point, the rest of the instructions assume that you are executing commands from inside the Docker Container.

## Delete Octopress dir + clone your Octopress repo

The Docker container will contain an Octopress directory, but it's not needed.

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

NOTE: I have no idea why `bundle exec` is required here, I just used this in reponse to a previous error message and it's accompanying suggestion.

If this gives no errors, that's a good sign.

## Create a new blog post

```
$ bundle exec rake new_post["Setting up Octopress under Docker"]
```

It will tell you the path to the blog post.  Now open the file in your favorite editor and add contect.

## Push to Source branch

The source branch has the **source markdown content**.  It's actually the most important thing to preserve, because the HTML can always be regnerated from it.

```
$ git push origin source
```

## Deploy to Master branch

The master branch contains the **rendered HTML content**.  Here's how to push it up to your github pages repo (remember, in an earlier step you cloned your github pages repo at https://github.com/your-github-username/your-github-username.github.io.git)

```
$ bundle exec rake generate && bundle exec rake deploy
```

After the above command, the changes should be visible on your github pages blog (eg, your-username.github.io)



