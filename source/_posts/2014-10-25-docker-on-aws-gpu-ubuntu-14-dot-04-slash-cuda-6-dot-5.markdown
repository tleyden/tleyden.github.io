---
layout: post
title: "Docker on AWS GPU Ubuntu 14.04 / CUDA 6.5"
date: 2014-10-25 13:25
comments: true
categories: 
---

## Setup host instance

Before you can start your docker container, you will need to go **deeper down the rabbit hole**.  

You'll need to do the steps outlined in this blog post:

[Setting up an Ubuntu 14.04 box running on a GPU-enabled AWS instance](http://tleyden.github.io/blog/2014/10/25/cuda-6-dot-5-on-aws-gpu-instance-running-ubuntu-14-dot-04/)

After you're done, you'll end up with a host OS with the following properties:

* A GPU enabled AWS instance running Ubuntu 14.04
* Nvidia kernel module
* Nvidia device drivers
* CUDA 6.5 installed and verified

## Architecture

![architecture diagram](http://tleyden-misc.s3.amazonaws.com/blog_images/docker_gpu_aws_onion.png)

## Install Docker 

If you don't already have docker installed on your host, you'll need to install it.  At the time of this writing, this will install docker version 1.3.

Setup the key for the docker repo:

```
$ sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
```

Add the docker repo:

```
$ sudo sh -c "echo deb https://get.docker.com/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
$ sudo apt-get update
```

Install docker:

```
$ sudo apt-get install lxc-docker
```


## Run GPU enabled docker image

If you search stack overflow about how to enable docker to access the GPU, you'll probably end up on this [stack overflow post](http://stackoverflow.com/questions/25185405/using-gpu-from-a-docker-container).  The current winning answer is actually *the wrong way to do it* according to the docker folks I talked to on irc.  Here's the right way:

**Find all your nvidia devices**

```
$ ls -la /dev | grep nvidia
```

You should see:

```
crw-rw-rw-  1 root root    195,   0 Oct 25 19:37 nvidia0
crw-rw-rw-  1 root root    195, 255 Oct 25 19:37 nvidiactl
crw-rw-rw-  1 root root    251,   0 Oct 25 19:37 nvidia-uvm
```

**Launch docker container**

I've created a [docker image](https://registry.hub.docker.com/u/tleyden5iwx/ubuntu-cuda/) that has the cuda drivers pre-installed.  The [dockerfile](https://registry.hub.docker.com/u/tleyden5iwx/ubuntu-cuda/dockerfile/) is available on dockerhub if you want to know how this image was built.

You may have to adapt the following `docker run` command to match your particular devices.

To start the docker container, run:

```
$ export DOCKER_NVIDIA_DEVICES="--device /dev/nvidia0:/dev/nvidia0 --device /dev/nvidiactl:/dev/nvidiactl --device /dev/nvidia-uvm:/dev/nvidia-uvm"
$ sudo docker run -ti $DOCKER_NVIDIA_DEVICES tleyden5iwx/ubuntu-cuda /bin/bash
```

After running the above command, you should be at a shell inside your docker container:

```
root@1149788c731c:# 
```

## Verify CUDA access from inside the docker container

**Install CUDA samples**

```
$ cd /opt/nvidia_installers
$ ./cuda-samples-linux-6.5.14-18745345.run -noprompt -cudaprefix=/usr/local/cuda-6.5/
```

**Build deviceQuery sample**

```
$ cd /usr/local/cuda/samples/1_Utilities/deviceQuery
$ make
$ ./deviceQuery   
```

**You should see the following output**

```
deviceQuery, CUDA Driver = CUDART, CUDA Driver Version = 6.5, CUDA Runtime Version = 6.5, NumDevs = 1, Device0 = GRID K520
Result = PASS
```

## References

* https://registry.hub.docker.com/u/tleyden5iwx/ubuntu-cuda/
* http://stackoverflow.com/questions/25185405/using-gpu-from-a-docker-container
* http://docs.docker.com/installation/ubuntulinux/#ubuntu-trusty-1404-lts-64-bit