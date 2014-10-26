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

## Host setup

Your host OS (eg, the thing that runs the docker container, in this case Ubuntu 14.04 running on an AWS instance) will need to have the Nvidia kernel module loaded and the CUDA drivers installed.

The easiest way to get it working is to follow these instructions on [setting up CUDA 6.5 on AWS GPU Instance Running Ubuntu 14.04](http://tleyden.github.io/blog/2014/10/25/cuda-6-dot-5-on-aws-gpu-instance-running-ubuntu-14-dot-04/).  

You can either use the pre-built AMI, or build it from scratch yourself. 

## Run the docker container

You will need to adapt this command to match your particular nvidia devices.  See  [Docker on AWS GPU Ubuntu 14.04 / CUDA 6.5](http://tleyden.github.io/blog/2014/10/25/cuda-6-dot-5-on-aws-gpu-instance-running-ubuntu-14-dot-04/) for more details.

```
$ export DOCKER_NVIDIA_DEVICES="--device /dev/nvidia0:/dev/nvidia0 --device /dev/nvidiactl:/dev/nvidiactl --device /dev/nvidia-uvm:/dev/nvidia-uvm"
$ sudo docker run -ti $DOCKER_NVIDIA_DEVICES tleyden5iwx/caffe-gpu /bin/bash
```

It's a large docker image, so this might be a good time to [watch Portlandia on YouTube](https://www.youtube.com/watch?v=zz-7d3HZE7o) while it downloads.  

## Run caffe test suite

```
$ cd /opt/caffe
$ make test && make runtest
```

**Expected Result:** `... [  PASSED  ] 838 tests.`

## Run the MNIST LeNet example

```
$ cd /opt/caffe/data/mnist
$ ./get_mnist.sh
$ cd ../../examples/mnist
$ ./create_mnist.sh
$ ./train_lenet.sh
```

**Expected output:**

```
libdc1394 error: Failed to initialize libdc1394 
I1018 17:02:23.552733    66 caffe.cpp:90] Starting Optimization 
I1018 17:02:23.553583    66 solver.cpp:32] Initializing solver from parameters:
... lots of output ...
I1018 17:17:58.684598    66 caffe.cpp:102] Optimization Done.
```

Congratulations, you've got GPU-powered Caffe running!

# References

 - [tleyden5iwx/caffe-gpu](https://registry.hub.docker.com/u/tleyden5iwx/caffe-gpu) Docker image
 - [tleyden5iwx/caffe](https://registry.hub.docker.com/u/tleyden5iwx/caffe) Docker image (CPU-only)
 - [Docker on AWS GPU Ubuntu 14.04 / CUDA 6.5](http://tleyden.github.io/blog/2014/10/25/cuda-6-dot-5-on-aws-gpu-instance-running-ubuntu-14-dot-04/)
 - [CUDA 6.5 on AWS GPU Instance Running Ubuntu 14.04](http://tleyden.github.io/blog/2014/10/25/cuda-6-dot-5-on-aws-gpu-instance-running-ubuntu-14-dot-04/)
 