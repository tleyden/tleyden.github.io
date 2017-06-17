---
layout: post
title: "Running PostgreSQL in Docker"
date: 2017-06-14 08:01
comments: true
categories: postgresql docker
---

This walks you through:

1. Running Postgres locally in a docker container using docker networking (rather than the deprecated container links functionality that is mentioned in the [Postgres Docker instructions](https://hub.docker.com/_/postgres/).
1. Deploying to Docker Cloud

# Basic Postgres container with docker networking

## Create a user defined network

```
$ docker network create --driver bridge postgres-network
```

## Launch Postgres in that network 

The main parameter you will need to provide to postgres is a root db password.  Replace `*********` with a good password and run this command:

```
$ docker run --name postgres1 --network postgres-network -e POSTGRES_PASSWORD=********* -d postgres
```

## Launch psql and connect to Postgres

```
$ docker run -it --rm --network postgres-network postgres psql -h postgres1 -U postgres
Password for user postgres: <enter password used earlier>
psql (9.6.3)
Type "help" for help.

postgres=#
```

You now have a working postgres database server.

# Using a mounted volume for persistence

When running postgres under docker, most likely want to persist the database files on the host, rather than having them in the container.   

First, remove the previous container with:

```
$ docker stop postgres1 && docker rm postgres1
```

Go into the `/tmp` directory:

```
$ cd /tmp
```

Launch a container and use `/tmp/pgdata` as the host directory to mount as a volume mount, which will be mounted in the container in `/var/lib/postgresql/data`, which is the default location where Postgres stores it's data.  The `/tmp/pgdata` directory will be created on the host if it doesn't already exist.

```
$ docker run --name postgres1 --network postgres-network -v /tmp/pgdata:/var/lib/postgresql/data -e POSTGRES_PASSWORD=*************** -d postgres
```

List the contents of `/tmp/pgdata` and you should see several Postgres files:

```
$ ls pgdata/
PG_VERSION		pg_hba.conf		pg_serial		pg_twophase ...
```

# Launch phppgadmin Container

## First create a user

```
$ docker run -it --rm --network postgres-network postgres /bin/bash
```

Now you will be in a shell inside the docker container 

```
# createuser testuser -P --createdb -h postgres1 -U postgres
Enter password for new role: *******
Enter it again: ******
Password: <enter postgres password from earlier>
```

## Launch pgpadmin

```
 $ docker run --name phppgadmin --network postgres-network -ti -d -p 8080:80 -e DB_HOST=postgres1 keepitcool/phppgadmin
```

## Login

In your browser, open [http://localhost:8080/](http://localhost:8080/) and you should see the phpadmin login screen:

![loginscreen](http://tleyden-misc.s3.amazonaws.com/blog_images/phppgadmin.png)

Login with user/pass credentials created earlier:

* **username**: `testuser`
* **password**: `**********`

![postlogin](http://tleyden-misc.s3.amazonaws.com/blog_images/phpadmin_post_login.png)

# Deploying to Docker Cloud

## Deploy Stack

Create a new stack and paste it into the box

```
postgres-server:
  autoredeploy: true
  environment:
    - POSTGRES_PASSWORD=***************
  image: 'postgres:latest'
  volumes:
    - '/var/lib/postgresql/data:/var/lib/postgresql/data'
phppgadmin:
  autoredeploy: true
  environment:
    - DB_HOST=postgres-server
  image: 'keepitcool/phppgadmin:latest'
  ports:
    - '8085:80'
```

For example:

![Docker Cloud](http://tleyden-misc.s3.amazonaws.com/blog_images/docker_cloud_create_stack.png)


## Create user

Find the postgres-server container and hit the **Terminal** menu to get a shell on that container.

Enter:

```
# createuser testuser -P --createdb -h localhost -U postgres 
Enter password for new role: *******
Enter it again: *********
```

## Login to Web UI

Find the phppgadmin service in the Docker Cloud Web UI, and look for the service endpoint, which should look something like this: 

[http://phppgadmin.postgres.071a32d40.svc.dockerapp.io:8085/](http://phppgadmin.postgres.071a32d40.svc.dockerapp.io:8085/)

Login with user/pass credentials created earlier:

* **username**: `testuser`
* **password**: `**********`