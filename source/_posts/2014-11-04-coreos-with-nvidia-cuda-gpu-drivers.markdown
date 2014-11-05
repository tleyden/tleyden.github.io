---
layout: post
title: "CoreOS with Nvidia CUDA GPU drivers"
date: 2014-11-04 07:08
comments: true
categories: coreos gpu nvidia docker
---

This will walk you through installing the Nvidia GPU kernel module and CUDA drivers on a docker container running inside of CoreOS.

![architecture diagram](http://tleyden-misc.s3.amazonaws.com/blog_images/coreos-nvidia-gpu.png)

## Launch CoreOS on an AWS GPU instance

* Launch a new EC2 instance

* Under "Community AMIs", search for **ami-7c8b3f14**

* Select the GPU instances: **g2.2xlarge**

* Increase root EBS store from 8 GB -> 20 GB to give yourself some breathing room

## ssh into CoreOS instance

```
$ ssh -A core@ec2-54-80-24-46.compute-1.amazonaws.com
```

## Run docker container in privileged mode

```
$ sudo docker run --privileged=true -i -t ubuntu:12.04 /bin/bash
```

After the above command, you should be inside a root shell in your docker container.  The rest of the steps will assume this.

## Install build tools + other required packages

```
$ apt-get update
$ apt-get install build-essential wget git
```

## Prepare CoreOS kernel source


**Clone CoreOS kernel repository**

```
$ mkdir -p /usr/src/kernels
$ cd /usr/src/kernels
$ git clone https://github.com/coreos/linux.git
```

**Get CoreOS kernel version**

```
$ uname -a
Linux ip-10-183-54-167.ec2.internal 3.15.8+ #2 SMP Fri Sep 26 08:37:17 UTC 2014 x86_64 Intel(R) Xeon(R) CPU E5-2670 0 @ 2.60GHz GenuineIntel GNU/Linux
```

The CoreOS kernel version is **3.15.8**

**Switch correct branch for this kernel version **

```
$ cd linux
$ git checkout remotes/origin/coreos/v3.15.8
```

**Create kernel configuration file**

```
$ zcat /proc/config.gz > /usr/src/kernels/linux/.config
```

**Prepare kernel source for building modules**

```
$ cd /usr/src/kernels/linux
$ make modules_prepare
```

Now you should be ready to install the nvidia driver.

## Install nvidia driver

**Download**

```
$ mkdir -p /opt/nvidia
$ cd /opt/nvidia
$ wget http://developer.download.nvidia.com/compute/cuda/6_5/rel/installers/cuda_6.5.14_linux_64.run
```

**Unpack**

```
$ chmod +x cuda_6.5.14_linux_64.run
$ mkdir nvidia_installers
$ ./cuda_6.5.14_linux_64.run -extract=`pwd`/nvidia_installers
```

**Install**

```
$ cd nvidia_installers
$ ./NVIDIA-Linux-x86_64-340.29.run --kernel-source-path=/usr/src/kernels/linux/
```

**Installer Questions**

* Install NVidia's 32-bit compatibility libraries? **YES**
* Would you like to run nvidia-xconfig? **NO**

If everything worked, you should see:

![nvidia drivers installed](http://tleyden-misc.s3.amazonaws.com/blog_images/nvidia_driver_installed.png)

## Load nvidia kernel module

```
$ modprobe nvidia
```

No errors should be returned.  Verify it's loaded by running:

```
$ lsmod | grep -i nvidia
```

and you should see:

```
nvidia              10533711  0
i2c_core               41189  2 nvidia,i2c_piix4
```

## Install CUDA

```
$ ./cuda-linux64-rel-6.5.14-18749181.run
$ ./cuda-samples-linux-6.5.14-18745345.run
```

## Verify CUDA

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

Congratulations!  You now have a docker container running under CoreOS that can access the GPU. 

## Appendix A: Expose GPU to other docker containers

If you need *other* docker containers on this CoreOS instance to be able to access the GPU, you can do the following steps.

**Exit docker container**

```
$ exit
```

You should be back to your CoreOS shell.

**Add nvidia device nodes**

```
$ wget https://gist.githubusercontent.com/tleyden/74f593a0beea300de08c/raw/95ed93c5751a989e58153db6f88c35515b7af120/nvidia_devices.sh
$ chmod +x nvida_devices.sh
$ sudo ./nvida_devices.sh
```

**Verify device nodes**

```
$ ls -alh /dev | grep -i nvidia
crw-rw-rw-  1 root root  251,   0 Nov  5 16:37 nvidia-uvm
crw-rw-rw-  1 root root  195,   0 Nov  5 16:37 nvidia0
crw-rw-rw-  1 root root  195, 255 Nov  5 16:37 nvidiactl
```

**Launch docker containers**

When you launch other docker containers on the same CoreOS instance, to allow them to access the GPU device you will need to add the following arguments:

```
$ sudo docker run -ti --device /dev/nvidia0:/dev/nvidia0 --device /dev/nvidiactl:/dev/nvidiactl --device /dev/nvidia-uvm:/dev/nvidia-uvm tleyden5iwx/ubuntu-cuda /bin/bash
```

A complete example is available in [Docker on AWS GPU Ubuntu 14.04 / CUDA 6.5](http://tleyden.github.io/blog/2014/10/25/docker-on-aws-gpu-ubuntu-14-dot-04-slash-cuda-6-dot-5/).  You can pick up at th **Run GPU enabled docker image** step.


## References

* https://groups.google.com/forum/#!topic/coreos-user/CSp_wSywmI4
* [Docker on AWS GPU Ubuntu 14.04 / CUDA 6.5](http://tleyden.github.io/blog/2014/10/25/docker-on-aws-gpu-ubuntu-14-dot-04-slash-cuda-6-dot-5/)
* http://developer.download.nvidia.com/compute/cuda/6_0/rel/docs/CUDA_Getting_Started_Linux.pdf