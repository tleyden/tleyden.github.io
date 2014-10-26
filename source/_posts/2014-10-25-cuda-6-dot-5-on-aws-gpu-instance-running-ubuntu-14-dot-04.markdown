---
layout: post
title: "CUDA 6.5 on AWS GPU instance running Ubuntu 14.04"
date: 2014-10-25 11:56
comments: true
categories: aws, gpu
---

## Using a pre-built public AMI

Based on the instructions in this blog post, I've created an AMI and shared it publicly.  So the easiest thing to do is just use that pre-built AMI:

* Image: ami-2cbf3e44 (Ubuntu Server 14.04 LTS (HVM) - CUDA 6.5) 
* Instance type: g2.2xlarge
* Storage: Use at least 8 GB, 20+ GB recommended

If you use the pre-built AMI, then you can skip the rest of this article, since all of these steps are "baked in" to the AMI.

## Building from scratch

Or if you prefer to build your own instance from scratch, keep reading.

Create a new EC2 instance:

* Image: ami-9eaa1cf6 (Ubuntu Server 14.04 LTS (HVM), SSD Volume Type)
* Instance type: g2.2xlarge
* Storage: Use at least 8 GB, 20+ GB recommended

Install build-essential:

```
$ apt-get update && apt-get install build-essential
```

Get CUDA installer:

```
$ wget http://developer.download.nvidia.com/compute/cuda/6_5/rel/installers/cuda_6.5.14_linux_64.run
```

Extract CUDA installer:

```
$ chmod +x cuda_6.5.14_linux_64.run
$ mkdir nvidia_installers
$ ./cuda_6.5.14_linux_64.run -extract=`pwd`/nvidia_installers
```


Run Nvidia driver installer:

```
$ cd nvidia_installers
$ ./NVIDIA-Linux-x86_64-340.29.run
```

At this point it will popup an 8-bit UI that will ask you to accept a license agreement, and then start installing.

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/install_cuda.png)

At this point, I got an error:

```
Unable to load the kernel module 'nvidia.ko'.  This happens most frequently when this kernel module was built against the wrong or
         improperly configured kernel sources, with a version of gcc that differs from the one used to build the target kernel, or if a driver
         such as rivafb, nvidiafb, or nouveau is present and prevents the NVIDIA kernel module from obtaining ownership of the NVIDIA graphics
         device(s), or no NVIDIA GPU installed in this system is supported by this NVIDIA Linux graphics driver release.

         Please see the log entries 'Kernel module load error' and 'Kernel messages' at the end of the file '/var/log/nvidia-installer.log'
         for more information.
```

After [reading this forum post](https://devtalk.nvidia.com/default/topic/547588/error-installing-nvidia-drivers-on-x86_64-amazon-ec2-gpu-cluster-t20-gpu-/) I installed:

```
$ sudo apt-get install linux-image-extra-virtual
```

When it prompted me what do to about the grub changes, I chose "choose package maintainers version".

Reboot:

```
$ reboot
```

## Disable nouveau

At this point you need to disable nouveau, since it conflicts with the nvidia kernel module.

Open a new file

```
$ vi /etc/modprobe.d/blacklist-nouveau.conf
```

and add these lines to it

```
blacklist nouveau
blacklist lbm-nouveau
options nouveau modeset=0
alias nouveau off
alias lbm-nouveau off
```

and then save the file.

Disable the Kernel Nouveau:

```
$ echo options nouveau modeset=0 | sudo tee -a /etc/modprobe.d/nouveau-kms.conf
```

Reboot:

```
$ update-initramfs -u
$ reboot
```

## One more try -- this time it works

Get Kernel source:

```
$ apt-get install linux-source
$ apt-get install linux-headers-3.13.0-37-generic

```

Rerun Nvidia driver installer:

```
$ cd nvidia_installers
$ ./NVIDIA-Linux-x86_64-340.29.run
```

Load nvidia kernel module:

```
$ modprobe nvidia
```

Run CUDA + samples installer:

```
$ ./cuda-linux64-rel-6.5.14-18749181.run
$ ./cuda-samples-linux-6.5.14-18745345.run
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

* http://www.r-tutor.com/gpu-computing/cuda-installation/cuda6.5-ubuntu
* http://askubuntu.com/questions/451672/installing-and-testing-cuda-in-ubuntu-14-04
* https://devtalk.nvidia.com/default/topic/547588/error-installing-nvidia-drivers-on-x86_64-amazon-ec2-gpu-cluster-t20-gpu-/
* https://devtalk.nvidia.com/default/topic/769719/drm-ko-missing-on-ubuntu-14-04-1-lts-aws-ec2-g2-2xlarge-instance/
* http://askubuntu.com/questions/451221/ubuntu-14-04-install-nvidia-driver