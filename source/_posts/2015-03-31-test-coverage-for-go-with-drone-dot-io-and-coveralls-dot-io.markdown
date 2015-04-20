---
layout: post
title: "Test coverage for Go with drone.io and coveralls.io"
date: 2015-03-31 07:26
comments: true
categories: golang testing tooling
---

This will walk you through setting up a test coverage report on coveralls.io which will be updated every time a new build happens on drone.io (a continuous integration server similar to TavisCI).

I'm going to use the [couchbaselabs/sg-replicate](https://github.com/couchbaselabs/sg-replicate) repo as an example, since it currently does not have any test coverage statistics.  The goal is to end up with a badge in the README that points to a test coverage report hosted on coveralls.io.

## Clone the repo

```
$ git clone https://github.com/couchbaselabs/sg-replicate.git
$ cd sg-replicate
```

## Test coverage command line stats

```
$ go test -cover
go tool: no such tool "cover"; to install:
	go get golang.org/x/tools/cmd/cover

```

Try again:

```
$ go get golang.org/x/tools/cmd/cover && go test -cover
PASS
coverage: 69.4% of statements
ok  	github.com/couchbaselabs/sg-replicate	0.156s
```

Ouch, 69.4% is barely a C-. (if you round up!)

## Coverage breakdown

Text report:

```
$ go test -coverprofile=coverage.out 
$ go tool cover -func=coverage.out
github.com/couchbaselabs/sg-replicate/attachment.go:15:			NewAttachment			84.6%
github.com/couchbaselabs/sg-replicate/changes_feed_parameters.go:20:	NewChangesFeedParams		100.0%
github.com/couchbaselabs/sg-replicate/changes_feed_parameters.go:30:	FeedType			100.0%
github.com/couchbaselabs/sg-replicate/changes_feed_parameters.go:34:	Limit				100.0%
```

HTML report:

```
$ go test -coverprofile=coverage.out 
$ go tool cover -html=coverage.out
```

This should open up the following report in your default browser: 

![html report](http://tleyden-misc.s3.amazonaws.com/blog_images/go_coverage_html.png)

## Coveralls.io setup

* Login to coveralls.io
* Create a new repo 
* Get the repo token from the **SET UP COVERALLS** section

At this point, your empty coveralls repo will look something like this:

![empty coveralls repo](http://tleyden-misc.s3.amazonaws.com/blog_images/coveralls_empty_repo.png)

## Configure Drone.io + Goveralls

If you have not already done so, setup a drone.io build for your repo.

On the drone.io **Settings** page, make the following changes:

**Environment Variables**

In the Environment Variables section of the web ui, add:

```
COVERALLS_TOKEN=<coveralls_repo_token>
```

**Commands**

In the commands section, you can replace your existing `go test` call with:

```
go get github.com/axw/gocov/gocov
go get github.com/mattn/goveralls
goveralls -service drone.io -repotoken $COVERALLS_TOKEN
```

Here's what it should look like:

![drone io ui](http://tleyden-misc.s3.amazonaws.com/blog_images/drone_io_coverage.png)

## Kick off a build

Go to the drone.io project page for your repo, and hit **Build Now**

At the bottom of the build output, you should see:

```
Job #1.1
https://coveralls.io/jobs/5189501
```

If you follow the link, you should see something like:

![coveralls report](http://tleyden-misc.s3.amazonaws.com/blog_images/coveralls_sgreplicate.png)

Looks like we just went from a C- to a B!  I have no idea why the coverage improved, but I'll take it.

## Add a badge, call it a day

On the coveralls.io project page for your repo, you should see a button near the top called **Badge URLS**.  Click and copy/paste the markdown, which should look something like this:

```
[![Coverage Status](https://coveralls.io/repos/couchbaselabs/sg-replicate/badge.svg?branch=master)](https://coveralls.io/r/couchbaselabs/sg-replicate?branch=master)
```

And add it to your project's README.  

![badges](http://tleyden-misc.s3.amazonaws.com/blog_images/sg_replicate_badges.png)


## References

* https://blog.golang.org/cover
* https://github.com/mattn/goveralls

