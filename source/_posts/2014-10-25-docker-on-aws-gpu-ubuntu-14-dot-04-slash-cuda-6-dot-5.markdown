---
layout: post
title: "Docker on AWS GPU Ubuntu 14.04 / CUDA 6.5"
date: 2014-10-25 13:25
comments: true
categories: 
---

## Setup host instance

Follow the instructions in [setting up an Ubuntu 14.04 box running on a GPU-enabled AWS instance](http://tleyden.github.io/blog/2014/10/25/cuda-6-dot-5-on-aws-gpu-instance-running-ubuntu-14-dot-04/).  You will end up with a host OS:

* A GPU enabled AWS instance running Ubuntu 14.04
* Nvidia kernel module
* Nvidia device drivers
* CUDA 6.5 installed and verified

## Install Docker 

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

Find all your nvidia devices:

```
$ ls -la /dev | grep nvidia
```

You should see:

```
crw-rw-rw-  1 root root    195,   0 Oct 25 19:37 nvidia0
crw-rw-rw-  1 root root    195, 255 Oct 25 19:37 nvidiactl
crw-rw-rw-  1 root root    251,   0 Oct 25 19:37 nvidia-uvm
```

Run ubuntu and tell lxc to allow access to the nvidia devices:

```
$ sudo docker run -ti -v /home/ubuntu/:/mnt --device /dev/nvidia0:/dev/nvidia0 --device /dev/nvidiactl:/dev/nvidiactl --device /dev/nvidia-uvm:/dev/nvidia-uvm ubuntu:14.04 /bin/bash
```

*Note: the above command mounts a volume and makes a lot of assumptions about what is inside /home/ubuntu, based on previous things downloaded in the companion blog article on [setting up an Ubuntu 14.04 box running on a GPU-enabled AWS instance](http://tleyden.github.io/blog/2014/10/25/cuda-6-dot-5-on-aws-gpu-instance-running-ubuntu-14-dot-04/).  Hopefully this will get cleaned up.*

After running the above command, you should be at a shell inside your docker container:

```
root@1149788c731c:# 
```

## Inside the docker image

Get build tools:

```
$ apt-get update && apt-get install -y build-essential
```

Install NVIDIA driver:

```
$ cd /mnt/nvidia_installers
$ ./NVIDIA-Linux-x86_64-340.29.run -s -N --no-kernel-module
```

and don't worry about the warning about `--no-kernel-module`.

Install CUDA + samples:

```
$ ./cuda-linux64-rel-6.5.14-18749181.run -noprompt
$ ./cuda-samples-linux-6.5.14-18745345.run -noprompt -cudaprefix=/usr/local/cuda-6.5/

```

## Verify CUDA is correctly installed

```
$ cd /usr/local/cuda/samples/1_Utilities/deviceQuery
$ make
$ ./deviceQuery   
```

You should see the following output:

```
deviceQuery, CUDA Driver = CUDART, CUDA Driver Version = 6.5, CUDA Runtime Version = 6.5, NumDevs = 1, Device0 = GRID K520
Result = PASS
```

## References

* http://stackoverflow.com/questions/25185405/using-gpu-from-a-docker-container
* http://docs.docker.com/installation/ubuntulinux/#ubuntu-trusty-1404-lts-64-bit