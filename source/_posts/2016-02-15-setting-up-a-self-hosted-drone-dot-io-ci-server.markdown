---
layout: post
title: "Setting up a self-hosted drone.io CI server"
date: 2016-02-15 19:37
comments: true
categories: ci
---

## Spin up AWS server

* Ubuntu Server 14.04 LTS (HVM), SSD Volume Type - ami-fce3c696
* m3.medium
* 250MB magnetic storage

## Install docker

`ssh ubuntu@<aws-instance>` and [install docker](https://docs.docker.com/engine/installation/linux/ubuntulinux/)

## Register github application

Go to github and [register](https://github.com/settings/applications/new) a new OAuth application using the following values:

* **Application name** Couchbase Mobile Drone CI
* **Homepage URL** http://ec2-54-163-185-45.compute-1.amazonaws.com
* **Application description** Couchbase Mobile Drone CI
* **Authorization callback URL** http://ec2-54-163-185-45.compute-1.amazonaws.com/authorize

It will give you a **Client ID** and **Client Secret**

## Create `/etc/drone/dronerc` config file

On the ubuntu host:

```
$ sudo mkdir /etc/drone
$ emacs /etc/drone/dronerc
```

**Configure Remote Driver**

Add these values:

```
REMOTE_DRIVER=github
REMOTE_CONFIG=https://github.com?client_id=${client_id}&client_secret=${client_secret}
```

and replace `client_id` and `client_secret` with the values returned from github.

**Configure Database**

Add these values:

```
DATABASE_DRIVER=sqlite3
DATABASE_CONFIG=/var/lib/drone/drone.sqlite
```

## Run Docker container

```
sudo docker run \
	--volume /var/lib/drone:/var/lib/drone \
	--volume /var/run/docker.sock:/var/run/docker.sock \
	--env-file /etc/drone/dronerc \
	--restart=always \
	--publish=80:8000 \
	--detach=true \
	--name=drone \
	drone/drone:0.4
```

Check the logs via `docker logs <container-id>` and they should look something like [this](https://gist.github.com/tleyden/db0a894c30b4811a5deb)


## Edit AWS security group

With your instance selected, look for the security groups in the instance details:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/drone_setup_security_group.png)

Add a new inbound port with the following settings:

* **Protocol** TCP
* **Port Range** 80
* **Source** 0.0.0.0

It should look like this when you're done:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/drone_setup_security_group2.png)


## Verify it's running

Paste the hostname of your aws instance into your browser (eg, `http://ec2-54-163-185-45.compute-1.amazonaws.com`), and you should see a page like this:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/drone_login_screen.png)

## Login

If you click the login button, you should see:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/drone_github_authorize.png)

And then:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/drone_post_github_login.png)


## Activate a repository

Click one of the repositories you have access to, and you should get an "activate now" option:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/drone_activate_now.png)

which will take you to your project home screen:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/drone_project_home.png)

## Add a `.drone.yml` file to the root of the repository

In the repository you have chosen (in my case I'm using `tleyden/sync_gateway`, which is a golang project, and may refer to it later), add a `.drone.yml` file to the root of the repository with:

```
build:
  image: golang
  commands:
    - go get
    - go build
    - go test
```

Commit your change, but do not push to github yet, that will be in the next step.

```
$ git add .drone.yml
$ git commit -m "Add drone.yml"
```

## Kickoff a build

Now push your change up to github.

```
$ git push origin master
```

and in your drone UI you should see a build in progress:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/drone_build_running.png)

when it finishes, you'll see either a pass or a failure.  If you get a failure (which I did), it will look like this:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/drone_build_failure.png)


## Manually triggering another build

In my case, the above failure was due to a dependency not building.  Since nothing else needs to be pushed to the repo to fix the build, I'm just going to manually trigger a build.

On the build failure screen above, there is a **Restart** button, which triggers a new build.

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/drone_build_success.png)

Now it works!










