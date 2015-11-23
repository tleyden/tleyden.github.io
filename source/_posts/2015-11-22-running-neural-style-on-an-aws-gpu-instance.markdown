---
layout: post
title: "Running Neural Style on an AWS GPU instance"
date: 2015-11-22 11:02
comments: true
categories: deeplearning, gpu, docker
---

These instructions will walk you through getting [neural-style](https://github.com/jcjohnson/neural-style) up and running on an AWS GPU instance.

## Spin up CUDA-enabled AWS instance

Follow these instructions to [install CUDA 7.5 on AWS GPU Instance Running Ubuntu 14.04](http://tleyden.github.io/blog/2015/11/22/cuda-7-dot-5-on-aws-gpu-instance-running-ubuntu-14-dot-04/).

## SSH into AWS instance

```
$ ssh ubuntu@<instance-ip>
```

## Install Docker 

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
$ sudo make
$ sudo ./deviceQuery
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

## Start Docker container

```
$ export DOCKER_NVIDIA_DEVICES="--device /dev/nvidia0:/dev/nvidia0 --device /dev/nvidiactl:/dev/nvidiactl --device /dev/nvidia-uvm:/dev/nvidia-uvm"
$ sudo docker run -ti $DOCKER_NVIDIA_DEVICES kaixhin/cuda-torch /bin/bash
```

## Re-install CUDA 7.5 in the Docker container

As [reported in the Torch7 Google Group](https://groups.google.com/d/msg/torch7/yCSNIzW590M/Af7CHXEdDQAJ) and in [Kaixhin/dockerfiles](https://github.com/Kaixhin/dockerfiles/issues/6), there is an API version mismatch with the docker container and the host's version of CUDA.

The workaround is to re-install CUDA 7.5 via:

```
$ wget http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-repo-ubuntu1404_7.5-18_amd64.deb
$ sudo dpkg -i cuda-repo-ubuntu1404_7.5-18_amd64.
deb
$ sudo apt-get update
$ sudo apt-get upgrade -y
$ sudo apt-get install -y opencl-headers build-essential protobuf-compiler \
    libprotoc-dev libboost-all-dev libleveldb-dev hdf5-tools libhdf5-serial-dev \
    libopencv-core-dev  libopencv-highgui-dev libsnappy-dev libsnappy1 \
    libatlas-base-dev cmake libstdc++6-4.8-dbg libgoogle-glog0 libgoogle-glog-dev \
    libgflags-dev liblmdb-dev git python-pip gfortran
$ sudo apt-get clean
$ sudo apt-get install -y linux-image-extra-`uname -r` linux-headers-`uname -r` linux-image-`uname -r`
$ sudo apt-get install -y cuda
```

## Verify CUDA inside docker container

Running:

```
$ nvidia-smi 
```

Should show info about the GPU driver and not return any errors.

Running this torch command:

```
$ th -e "require 'cutorch'; require 'cunn'; print(cutorch)"
```

Should produce this output:

```
{
  getStream : function: 0x4054b760
  getDeviceCount : function: 0x408bca58
  .. etc
}
```

## Install neural-style

The following should be run **inside** the docker container:

```
$ apt-get install -y wget libpng-dev libprotobuf-dev protobuf-compiler
$ git clone --depth 1 https://github.com/jcjohnson/neural-style.git
$ /root/torch/install/bin/luarocks install loadcaffe
```

**Download models**

```
$ cd neural-style
$ sh models/download_models.sh
```

## Run neural style

First, grab a few images to test with

```
$ mkdir images
$ wget https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg/1280px-Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg -O images/vangogh.jpg
$ wget http://exp.cdn-hotels.com/hotels/1000000/10000/7500/7496/7496_42_z.jpg -O images/hotel_del_coronado.jpg
```

Run it:

```
$ th neural_style.lua -style_image images/vangogh.jpg -content_image images/hotel_del_coronado.jpg
```
