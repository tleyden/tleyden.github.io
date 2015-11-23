---
layout: post
title: "Docker on AWS GPU Ubuntu 14.04 / CUDA 6.5"
date: 2014-10-25 13:25
comments: true
categories: 
---

## Architecture

After going through the steps in this blog post, you'll end up with this:

![architecture diagram](http://tleyden-misc.s3.amazonaws.com/blog_images/docker_gpu_aws_onion.png)

## Setup host 

Before you can start your docker container, you will need to go **deeper down the rabbit hole**.  

You'll first need to complete the steps here:

[Setting up an Ubuntu 14.04 box running on a GPU-enabled AWS instance](http://tleyden.github.io/blog/2014/10/25/cuda-6-dot-5-on-aws-gpu-instance-running-ubuntu-14-dot-04/)

After you're done, you'll end up with a host OS with the following properties:

* A GPU enabled AWS instance running Ubuntu 14.04
* Nvidia kernel module
* Nvidia device drivers
* CUDA 6.5 installed and verified

## Install Docker 

Once your host OS is setup, you're ready to install docker.  The latest instructions are avaialable on the [Docker website](https://docs.docker.com/v1.8/installation/ubuntulinux/).  Currently for Ubuntu 14.0.4 you need to:

```
$ sudo apt-get update && sudo apt-get install curl
$ curl -sSL https://get.docker.com/ | sh
```

As the post-install message suggests, enable docker for non-root users:

```
$ sudo usermod -aG docker ubuntu
```

Verify correct install via:

```
$ sudo docker run hello-world
```

## Mount GPU devices

**Mount**

```
$ cd /usr/local/cuda/samples/1_Utilities/deviceQuery
$ ./deviceQuery
```

You should see something [like this](https://gist.github.com/tleyden/58ab2eedebc9529edb76):

```
./deviceQuery Starting...

 CUDA Device Query (Runtime API) version (CUDART static linking)

Detected 1 CUDA Capable device(s)

Device 0: "GRID K520"
  CUDA Driver Version / Runtime Version          6.5 / 6.5
  ... snip ...

deviceQuery, CUDA Driver = CUDART, CUDA Driver Version = 6.5, CUDA Runtime Version = 6.5, NumDevs = 1, Device0 = GRID K520
Result = PASS
```

**Verify: Find all your nvidia devices**

```
$ ls -la /dev | grep nvidia
```

You should see:

```
crw-rw-rw-  1 root root    195,   0 Oct 25 19:37 nvidia0
crw-rw-rw-  1 root root    195, 255 Oct 25 19:37 nvidiactl
crw-rw-rw-  1 root root    251,   0 Oct 25 19:37 nvidia-uvm
```

## Run GPU enabled docker image

**Launch docker container**

The easiest way to get going is to use this pre-built [docker image](https://registry.hub.docker.com/u/tleyden5iwx/ubuntu-cuda/) that has the cuda drivers pre-installed.  Or if you want to build your own, [the accompanying dockerfile](https://registry.hub.docker.com/u/tleyden5iwx/ubuntu-cuda/dockerfile/) will be a useful starting point.  (Update: Nvidia has released [an official docker container](https://github.com/nvidia/nvidia-docker) which you should probably use, but I haven't tried yet as of the time of this writing.  Please post a comment if you get this to work)

You'll have to adapt the `DOCKER_NVIDIA_DEVICES` variable below to match your particular devices.

To start the docker container, run:

```
$ DOCKER_NVIDIA_DEVICES="--device /dev/nvidia0:/dev/nvidia0 --device /dev/nvidiactl:/dev/nvidiactl --device /dev/nvidia-uvm:/dev/nvidia-uvm"
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