---
layout: post
title: "CUDA 7.5 on AWS GPU Instance Running Ubuntu 14.04"
date: 2015-11-22 17:32
comments: true
categories: aws gpu cuda
---

## Launch stock Ubuntu AMI 

* Launch **ami-d05e75b8**
* Choose a GPU instance type: **g2.2xlarge** or **g2.8xlarge**
* Increase the size of the storage (this depends on what else you plan to install, I'd suggest at least 20 GB)

## SSH in

```
$ ssh ubuntu@<instance ip>
```

## Install CUDA repository


```
$ wget http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-repo-ubuntu1404_7.5-18_amd64.deb
$ sudo dpkg -i cuda-repo-ubuntu1404_7.5-18_amd64.deb
```

## Update APT 

```
$ sudo apt-get update
$ sudo apt-get upgrade -y
$ sudo apt-get install -y opencl-headers build-essential protobuf-compiler \
    libprotoc-dev libboost-all-dev libleveldb-dev hdf5-tools libhdf5-serial-dev \
    libopencv-core-dev  libopencv-highgui-dev libsnappy-dev libsnappy1 \
    libatlas-base-dev cmake libstdc++6-4.8-dbg libgoogle-glog0 libgoogle-glog-dev \
    libgflags-dev liblmdb-dev git python-pip gfortran
```

You will get a dialog regarding the `menu.lst` file, just choose the default option it gives you.

Do some cleanup:

```
$ sudo apt-get clean
```

## DRM module workaround

```
$ sudo apt-get install -y linux-image-extra-`uname -r` linux-headers-`uname -r` linux-image-`uname -r`
```

For an explanation of why this is needed, see [Caffe on EC2 Ubuntu 14.04 Cuda 7](https://github.com/BVLC/caffe/wiki/Caffe-on-EC2-Ubuntu-14.04-Cuda-7) and search for this command.

## Install CUDA

```
$ sudo apt-get install -y cuda
$ sudo apt-get clean
```

## Verify CUDA

```
$ nvidia-smi
```

You should see:

```
+------------------------------------------------------+
| NVIDIA-SMI 352.63     Driver Version: 352.63         |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  GRID K520           Off  | 0000:00:03.0     Off |                  N/A |
| N/A   30C    P0    36W / 125W |     11MiB /  4095MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+

+-----------------------------------------------------------------------------+
| Processes:                                                       GPU Memory |
|  GPU       PID  Type  Process name                               Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+
```

Make sure kernel module and devices are present:

```
ubuntu@ip-10-33-135-228:~$ lsmod | grep -i nvidia
nvidia               8642880  0
drm                   303102  1 nvidia
ubuntu@ip-10-33-135-228:~$ ls -alh /dev | grep -i nvidia
crw-rw-rw-  1 root root    195,   0 Nov 23 01:59 nvidia0
crw-rw-rw-  1 root root    195, 255 Nov 23 01:58 nvidiactl
```

## References

* [Caffe on EC2 Ubuntu 14.04 Cuda 7](https://github.com/BVLC/caffe/wiki/Caffe-on-EC2-Ubuntu-14.04-Cuda-7)