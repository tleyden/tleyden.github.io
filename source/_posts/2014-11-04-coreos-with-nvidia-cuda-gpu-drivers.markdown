---
layout: post
title: "CoreOS with Nvidia CUDA GPU drivers"
date: 2014-11-04 07:08
comments: true
categories: coreos gpu nvidia cuda
---

## Launch CoreOS on AWS GPU instance

Click the "Launch Stack" button to launch your CoreOS instances via AWS Cloud Formation:

[<img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png">](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#cstack=sn%7ECouchbase-CoreOS%7Cturl%7Ehttp://tleyden-misc.s3.amazonaws.com/elastic-thought/coreos-stable-gpu-hvm.template)

*NOTE: this is hardcoded to use the us-east-1 region, so if you need a different region, you should edit the URL accordingly*

* Go to AWS control panel under EC2 instances 

* Launch a new instance

* Under "Community AMIs", search for `ami-d878c3b0`

* Select the GPU Instance: `ami-d878c3b0`

* Increase root EBS store from 8 GB -> 20 GB to give yourself some breathing room


## Run docker container in privileged mode

```
$ docker run --privileged=true -i -t ubuntu:12.04 /bin/bash
```

After the above command, you should be inside a shell in your docker container.  The rest of the steps will assume that you are running them from inside your docker container.

## Install build tools + other required packages

```
$ apt-get install build-essential wget git
```

## Upgrade GCC to 4.7

**Install**

```
$ apt-get install software-properties-common python-software-properties 
$ add-apt-repository ppa:ubuntu-toolchain-r/test
$ apt-get update
$ apt-get install gcc-4.7 g++-4.7
```

**Add GCC 4.7**

```
$ update-alternatives --remove gcc /usr/bin/gcc-4.6
$ update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.7 60 --slave /usr/bin/g++ g++ /usr/bin/g++-4.7
$ update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.6 40 --slave /usr/bin/g++ g++ /usr/bin/g++-4.6
```

**Make sure GCC 4.7 is the default alternative**

```
$ update-alternatives --config gcc
...
* 0 /usr/bin/gcc-4.7 60 auto mode
...
```

It should have gcc-4.7 as the default choice with the asterisk next to it.

## Get kernel source

```
$ mkdir -p /usr/src/kernels
$ cd /usr/src/kernels
$ git clone https://github.com/coreos/linux.git
```

Find the tag that corresponds to your CoreOS version.  For example, currently the latest stable version is the **v3.8** tag (I think).

```
$ git checkout v3.8
```

## Compile kernel source -- Take 1

If you don't do this step, you'll get an error about not having a `/usr/src/kernels/linux/include/linux/version.h` file when you run `NVIDIA-Linux-x86_64-340.29.run`.

```
$ https://raw.githubusercontent.com/coreos/coreos-overlay/f0de215426eede4d479c732ea1f575d99b978f3a/sys-kernel/coreos-kernel/files/x86_64_defconfig-3.16.2
$ mv x86_64_defconfig-3.16.2 .config
$ make
```

**Error**

```
root@373c6d823a5b:/usr/src/kernels/linux# make
  HOSTCC  scripts/kconfig/conf.o
  ...
scripts/kconfig/conf --silentoldconfig Kconfig
.config:2620:warning: symbol value 'm' invalid for USB_OHCI_HCD_PCI
.config:2622:warning: symbol value 'm' invalid for USB_OHCI_HCD_PLATFORM
.config:2984:warning: symbol value 'm' invalid for XEN_TMEM
warning: (BLK_DEV_RBD && CEPH_FS) selects CEPH_LIB which has unmet direct dependencies (NET && INET && EXPERIMENTAL)
*
* Restart config...
*
*
* General setup
*
Prompt for development and/or incomplete code/drivers (EXPERIMENTAL) [N/y/?] (NEW) n

```

I gave up on trying to use the kernel config from `coreos-overlay`, and tried a different direction.

## Compile kernel source -- Take 2

If you don't do this step, you'll get an error about not having a `/usr/src/kernels/linux/include/linux/version.h` file when you run `NVIDIA-Linux-x86_64-340.29.run`.

```
$ apt-get install libncurses5-dev
$ make menuconfig
```

When the screen pops up, just choose "Exit" and hit "Yes" when it asks you to save.  

```
$ make
```

This works, and the kernel will compile.  But it will end up in an error below when trying to run `NVIDIA-Linux-x86_64-340.29.run`.

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

**Error**

Using the "Take 2" method of compiling kernel source above, I got the following error when installing the kernel:

```
ERROR: Unable to load the kernel module 'nvidia.ko'.  This happens most frequently when this kernel module was built against the wrong or improperly configured kernel sources, with a
         version of gcc that differs from the one used to build the target kernel, or if a driver such as rivafb, nvidiafb, or nouveau is present and prevents the NVIDIA kernel module
         from obtaining ownership of the NVIDIA graphics device(s), or no NVIDIA GPU installed in this system is supported by this NVIDIA Linux graphics driver release.

         Please see the log entries 'Kernel module load error' and 'Kernel messages' at the end of the file '/var/log/nvidia-installer.log' for more information.
```

## Verify

TODO

## References

* https://groups.google.com/forum/#!topic/coreos-user/CSp_wSywmI4
* http://www.swiftsoftwaregroup.com/upgrade-gcc-4-7-ubuntu-12-04/