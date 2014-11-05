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

## References

* https://groups.google.com/forum/#!topic/coreos-user/CSp_wSywmI4
