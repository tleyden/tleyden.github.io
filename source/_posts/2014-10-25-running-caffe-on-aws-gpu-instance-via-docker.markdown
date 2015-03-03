---
layout: post
title: "Running Caffe on AWS GPU instance via Docker"
date: 2014-10-25 20:42
comments: true
categories: caffe docker aws gpu
---

This is a tutorial to help you get the [Caffe deep learning framework](http://caffe.berkeleyvision.org/) up and running on a GPU-powered AWS instance running inside a Docker container.

## Architecture

![architecture diagram](http://tleyden-misc.s3.amazonaws.com/blog_images/caffe_docker_aws_onion.png)

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

Once your host OS is setup, you're ready to install docker.  (version 1.3 at the time of this writing)

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

## Run the docker container

**Find your nvidia devices**

```
$ ls -la /dev | grep nvidia
```

You should see:

```
crw-rw-rw-  1 root root    195,   0 Oct 25 19:37 nvidia0
crw-rw-rw-  1 root root    195, 255 Oct 25 19:37 nvidiactl
crw-rw-rw-  1 root root    251,   0 Oct 25 19:37 nvidia-uvm
```

You'll have to adapt the `DOCKER_NVIDIA_DEVICES` variable below to match your particular devices.

Here's how to start the docker container:

```
$ DOCKER_NVIDIA_DEVICES="--device /dev/nvidia0:/dev/nvidia0 --device /dev/nvidiactl:/dev/nvidiactl --device /dev/nvidia-uvm:/dev/nvidia-uvm"
$ sudo docker run -ti $DOCKER_NVIDIA_DEVICES tleyden5iwx/caffe-gpu-master /bin/bash
```

It's a large docker image, so this might take a few minutes, depending on your network connection.

## Run caffe test suite

After the above `docker run` command completes, your shell will now be inside a docker container that has Caffe installed.  

You'll want run the Caffe test suite and make sure it passes.  This will validate your environment, including your GPU drivers.

```
$ cd /opt/caffe
$ make test && make runtest
```

**Expected Result:** `... [  PASSED  ] 838 tests.`

## Run the MNIST LeNet example

A more comprehensive way to verify your environment is to train the MNIST LeNet example:

```
$ cd /opt/caffe/data/mnist
$ ./get_mnist.sh
$ cd /opt/caffe
$ ./examples/mnist/create_mnist.sh
$ ./examples/mnist/train_lenet.sh
```

This will take a few minutes.

**Expected output:**

```
libdc1394 error: Failed to initialize libdc1394 
I1018 17:02:23.552733    66 caffe.cpp:90] Starting Optimization 
I1018 17:02:23.553583    66 solver.cpp:32] Initializing solver from parameters:
... lots of output ...
I1018 17:17:58.684598    66 caffe.cpp:102] Optimization Done.
```

Congratulations, you've got GPU-powered Caffe running in a docker container -- celebrate with a cup of [Philz](http://www.yelp.com/biz/philz-coffee-berkeley-2)!

# References

 - [tleyden5iwx/caffe-gpu-master](https://registry.hub.docker.com/u/tleyden5iwx/caffe-gpu-master) Caffe Docker image (GPU)
 - [tleyden5iwx/caffe-cpu-master](https://registry.hub.docker.com/u/tleyden5iwx/caffe-cpu-master) Caffe Docker image (CPU-only)
 - [Docker on AWS GPU Ubuntu 14.04 / CUDA 6.5](http://tleyden.github.io/blog/2014/10/25/cuda-6-dot-5-on-aws-gpu-instance-running-ubuntu-14-dot-04/)
 - [CUDA 6.5 on AWS GPU Instance Running Ubuntu 14.04](http://tleyden.github.io/blog/2014/10/25/cuda-6-dot-5-on-aws-gpu-instance-running-ubuntu-14-dot-04/)
 