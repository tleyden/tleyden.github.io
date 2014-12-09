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

* Under "Community AMIs", search for **ami-f669f29e** (CoreOS stable 494.4.0 (HVM))

* Select the GPU instances: **g2.2xlarge**

* Increase root EBS store from 8 GB -> 20 GB to give yourself some breathing room

## ssh into CoreOS instance

Find the public ip of the EC2 instance launched above, and ssh into it:

```
$ ssh -A core@ec2-54-80-24-46.compute-1.amazonaws.com
```


## Run Ubuntu 14 docker container in privileged mode

```
$ sudo docker run --privileged=true -i -t ubuntu:14.04 /bin/bash
```

After the above command, you should be inside a root shell in your docker container.  The rest of the steps will assume this.


## Install build tools + other required packages

In order to match the version of gcc that was used to build the CoreOS kernel.  (gcc 4.7)

```
# apt-get update
# apt-get install gcc-4.7 g++-4.7 wget git make dpkg-dev
```

**Set gcc 4.7 as default**

```
# update-alternatives --remove gcc /usr/bin/gcc-4.8
# update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.7 60 --slave /usr/bin/g++ g++ /usr/bin/g++-4.7
# update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 40 --slave /usr/bin/g++ g++ /usr/bin/g++-4.8
```

**Verify**

```
# update-alternatives --config gcc
```

It should list gcc 4.7 with an asterisk next to it:

```
* 0            /usr/bin/gcc-4.7   60        auto mode
```

## Prepare CoreOS kernel source

**Clone CoreOS kernel repository**

```
$ mkdir -p /usr/src/kernels
$ cd /usr/src/kernels
$ git clone https://github.com/coreos/linux.git
```

**Find CoreOS kernel version**

```
# uname -a
Linux ip-10-11-167-200.ec2.internal 3.17.2+ #2 SMP Tue Nov 4 04:15:48 UTC 2014 x86_64 Intel(R) Xeon(R) CPU E5-2670 0 @ 2.60GHz GenuineIntel GNU/Linux
```

The CoreOS kernel version is **3.17.2**

**Switch correct branch for this kernel version **

```
# cd linux
# git checkout remotes/origin/coreos/v3.17.2
```

**Create kernel configuration file**

```
# zcat /proc/config.gz > /usr/src/kernels/linux/.config
```

**Prepare kernel source for building modules**

```
# make modules_prepare
```

Now you should be ready to install the nvidia driver.

**Hack the kernel version**

In order to avoid [nvidia: version magic errors](https://gist.github.com/tleyden/2a46a86056e476976a8e#file-gistfile1-txt-L956), the following hack is required:

```
# sed -i -e 's/3.17.2/3.17.2+/' include/generated/utsrelease.h
```

I've [posted to the CoreOS Group](https://groups.google.com/d/msg/coreos-user/CSp_wSywmI4/CBHwocj8v9oJ) to ask why this hack is needed.

## Install nvidia driver

**Download**

```
# mkdir -p /opt/nvidia
# cd /opt/nvidia
# wget http://developer.download.nvidia.com/compute/cuda/6_5/rel/installers/cuda_6.5.14_linux_64.run
```

**Unpack**

```
# chmod +x cuda_6.5.14_linux_64.run
# mkdir nvidia_installers
# ./cuda_6.5.14_linux_64.run -extract=`pwd`/nvidia_installers
```

**Install**

```
# cd nvidia_installers
# ./NVIDIA-Linux-x86_64-340.29.run --kernel-source-path=/usr/src/kernels/linux/
```

**Installer Questions**

* Install NVidia's 32-bit compatibility libraries? **YES**
* Would you like to run nvidia-xconfig? **NO**

If everything worked, you should see:

![nvidia drivers installed](http://tleyden-misc.s3.amazonaws.com/blog_images/nvidia_driver_installed.png)

your `/var/log/nvidia-installer.log` should look something like [this](https://gist.github.com/tleyden/6d585fb8ab08154949c8)

## Load nvidia kernel module

```
# modprobe nvidia
```

No errors should be returned.  Verify it's loaded by running:

```
# lsmod | grep -i nvidia
```

and you should see:

```
nvidia              10533711  0
i2c_core               41189  2 nvidia,i2c_piix4
```

## Install CUDA

In order to fully verify that the kernel module is working correctly, install the CUDA drivers + library and run a device query.

To install CUDA:

```
# ./cuda-linux64-rel-6.5.14-18749181.run
# ./cuda-samples-linux-6.5.14-18745345.run
```

## Verify CUDA

```
# cd /usr/local/cuda/samples/1_Utilities/deviceQuery
# make
# ./deviceQuery   
```

You should see the following output:

```
deviceQuery, CUDA Driver = CUDART, CUDA Driver Version = 6.5, CUDA Runtime Version = 6.5, NumDevs = 1, Device0 = GRID K520
Result = PASS
```

Congratulations!  You now have a docker container running under CoreOS that can access the GPU. 

# Appendix: Expose GPU to other docker containers

If you need *other* docker containers on this CoreOS instance to be able to access the GPU, you can do the following steps.

**Exit docker container**

```
# exit
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

## References

* [Previous version of this blog post](https://github.com/tleyden/tleyden.github.io/blob/6d71759cc5e530efcae10d9c6012dd217f76795c/source/_posts/2014-11-04-coreos-with-nvidia-cuda-gpu-drivers.markdown)
* [CoreOS Google Group thread](https://groups.google.com/forum/#!topic/coreos-user/CSp_wSywmI4) - Thanks Сергей!
* [Docker on AWS GPU Ubuntu 14.04 / CUDA 6.5](http://tleyden.github.io/blog/2014/10/25/docker-on-aws-gpu-ubuntu-14-dot-04-slash-cuda-6-dot-5/)



















