---
layout: post
title: "Installing Autoware on Ubuntu 20.04"
date: 2022-10-19 14:10
comments: true
categories: 
---

This is a log of my experience installing Autoware on my bare metal laptop running Ubuntu 20.04.  I had a ton of stumbling blocks but stuck with it and eventually got it working.  I documented it along the way, so if you hit any of those same issues this might be useful to you.

As a warning, this blog post is pretty messy because of all those stumbling blocks, so you're probably better off just following the [official autoware installation docs](https://autowarefoundation.github.io/autoware-documentation/main/installation/) and referring to this in case you run into the same problems.

Good luck!!



<!-- TOC start -->
  * [My system](#my-system)
- [Pre-install steps](#pre-install-steps)
  * [Choose Ubuntu Linux version](#choose-ubuntu-linux-version)
  * [Docker vs source install](#docker-vs-source-install)
  * [Clean out old ros installs](#clean-out-old-ros-installs)
- [Installation (docker-based)](#installation-docker-based)
  * [Install docker engine](#install-docker-engine)
  * [Nvidia container toolkit](#nvidia-container-toolkit)
  * [Rocker](#rocker)
  * [Start autoware docker container](#start-autoware-docker-container)
    + [Error workaround](#error-workaround)
  * [Install vcstool](#install-vcstool)
  * [Setup workspace (from within container)](#setup-workspace-from-within-container)
- [Run a planning simulation](#run-a-planning-simulation)
  * [Install the gdown utility](#install-the-gdown-utility)
    + [Download maps](#download-maps)
  * [Launch autoware - take 1](#launch-autoware-take-1)
  * [Upgrade to CUDA 11.6](#upgrade-to-cuda-116)
  * [Upgrade to CUDA 11.6 - take 2](#upgrade-to-cuda-116-take-2)
    + [Fixing nvidia-smi error](#fixing-nvidia-smi-error)
  * [Start autoware docker container take 2](#start-autoware-docker-container-take-2)
  * [Install Nvidia container toolkit](#install-nvidia-container-toolkit)
  * [Install cuDNN](#install-cudnn)
  * [Install TensorRT](#install-tensorrt)
  * [Start autoware docker container take 3](#start-autoware-docker-container-take-3)
    + [Launch autoware take 2](#launch-autoware-take-2)
    + [Fix rviz2 errors](#fix-rviz2-errors)
  * [Start autoware docker container take 4](#start-autoware-docker-container-take-4)
    + [Launch autoware take 3](#launch-autoware-take-3)
- [References](#references)
<!-- TOC end -->
<!-- TOC --><a name="my-system"></a>
## My system

* Ubuntu 20.04
* System76 Oryx Pro laptop, 2017
* Nvidia GeForce GTX 1070
* Nvidia Driver Version: 470.141.03   CUDA Version: 11.4  (upgraded during this blog post to Driver Version: 510.73.05    CUDA Version: 11.6)


<!-- TOC --><a name="pre-install-steps"></a>
# Pre-install steps

<!-- TOC --><a name="choose-ubuntu-linux-version"></a>
## Choose Ubuntu Linux version

Autoware currently supports both 20.04 and 22.04 (but not 18.04), and I decided to go with 20.04 since it was the next LTS version after the version I had installed (18.04).

I noticed that autoware recommended cuda version of 11.6, which only has official downloads for 20.04 and not 22.04, so that made me think that Ubuntu 20.04 was the better choice.

Here are the steps to upgrade to Ubuntu 20.04: [official instructions](https://ubuntu.com/blog/how-to-upgrade-from-ubuntu-18-04-lts-to-20-04-lts-today).


<!-- TOC --><a name="docker-vs-source-install"></a>
## Docker vs source install

I decided to go with the easier docker install until I had a need to use the source install.

<!-- TOC --><a name="clean-out-old-ros-installs"></a>
## Clean out old ros installs

```
$ apt-get remove ros-dashing-*
$ apt-get remove ros-melodic-*
$ apt-get autoremove
```

<!-- TOC --><a name="installation-docker-based"></a>
# Installation (docker-based)

<!-- TOC --><a name="install-docker-engine"></a>
## Install docker engine

Install docker engine based on [these instructions](https://github.com/autowarefoundation/autoware/tree/0423b84ee8d763879bbbf910d249728410b16943/ansible/roles/docker_engine#manual-installation).  This links to the snapshot of the instructions that I used (as do below links).  If you want to use the latest instructions, change the `0423b84ee8d763879bbbf910d249728410b16943` commit hash in the URL to `main`.

<!-- TOC --><a name="nvidia-container-toolkit"></a>
## Nvidia container toolkit

Install the nvidia container toolkit based on [these instructions](https://github.com/autowarefoundation/autoware/tree/0423b84ee8d763879bbbf910d249728410b16943/ansible/roles/nvidia_docker#manual-installation).

After this step I was able to run `nvidia-smi` within the container:

```
root@apollo:/home/tleyden/Development# docker run --rm --gpus all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi
Thu Oct 20 05:28:27 2022       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 470.141.03   Driver Version: 470.141.03   CUDA Version: 11.4     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  NVIDIA GeForce ...  Off  | 00000000:01:00.0  On |                  N/A |
| N/A   39C    P8     6W /  N/A |    116MiB /  8119MiB |     14%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
+-----------------------------------------------------------------------------+

```

<!-- TOC --><a name="rocker"></a>
## Rocker

Rocker is an alternative to Docker compose used by Autoware.

Installed rocker based on [these instructions](https://github.com/autowarefoundation/autoware/tree/0423b84ee8d763879bbbf910d249728410b16943/ansible/roles/rocker#manual-installation).

After this step, running `rocker` shows the rocker help.

<!-- TOC --><a name="start-autoware-docker-container"></a>
## Start autoware docker container

I ran:

```
$ rocker --nvidia --x11 --user --volume $HOME/Development/autoware --volume $HOME/Development/autoware_map -- ghcr.io/autowarefoundation/autoware-universe:latest-cuda
```

but got this error:

```
Executing command: 
docker run --rm -it  --gpus all -v /home/tleyden/Development/autoware:/home/tleyden/Development/autoware -v /home/tleyden/Development/autoware_map:/home/tleyden/Development/autoware_map  -e DISPLAY -e TERM   -e QT_X11_NO_MITSHM=1   -e XAUTHORITY=/tmp/.docker_555jyzo.xauth -v /tmp/.docker_555jyzo.xauth:/tmp/.docker_555jyzo.xauth   -v /tmp/.X11-unix:/tmp/.X11-unix   -v /etc/localtime:/etc/localtime:ro  d0c01d5fe6d7 
docker: Error response from daemon: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: error running hook #0: error running hook: exit status 1, stdout: , stderr: Auto-detected mode as 'legacy'
nvidia-container-cli: requirement error: unsatisfied condition: cuda>=11.6, please update your driver to a newer version, or use an earlier cuda container: unknown.

```

<!-- TOC --><a name="error-workaround"></a>
### Error workaround

Using the approach suggested in [this github post](https://github.com/NVIDIA/nvidia-docker/issues/1409#issuecomment-1154910556) to add `-e NVIDIA_DISABLE_REQUIRE=true`, I ran the new command:

```
rocker -e NVIDIA_DISABLE_REQUIRE=true --nvidia --x11 --user --volume $HOME/Development/autoware --volume $HOME/Development/autoware_map -- ghcr.io/autowarefoundation/autoware-universe:latest-cuda

```

which seemed to work, as it dropped me into a container:

```
tleyden@86a918b83192:~/Development/autoware$ docker ps
bash: docker: command not found
```

Based on the response from the super helpful folks at Autoware in [this discussion](https://github.com/autowarefoundation/autoware/discussions/2961) I determined I needed to upgrade my Cuda version based on [these instructions](https://github.com/autowarefoundation/autoware/tree/0423b84ee8d763879bbbf910d249728410b16943/ansible/roles/cuda#manual-installation).  (see later step below)

<!-- TOC --><a name="install-vcstool"></a>
## Install vcstool

In the source instructions, it mentions that autoware depends on vcstool, which is a tool that makes it easy to manage code from multiple repos.

Install with:

```
curl -s https://packagecloud.io/install/repositories/dirk-thomas/vcstool/script.deb.sh | sudo bash
sudo apt-get update
sudo apt-get install python3-vcstool
```
<!-- TOC --><a name="setup-workspace-from-within-container"></a>
## Setup workspace (from within container)

In the container shell (started above):

```
cd autoware
mkdir src
vcs import src < autoware.repos
sudo apt update
rosdep update
rosdep install --from-paths . --ignore-src --rosdistro $ROS_DISTRO
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release
```

it took about 40 mins to build:

```
Summary: 238 packages finished [39min 59s]
  17 packages had stderr output: bag_time_manager_rviz_plugin elevation_map_loader grid_map_pcl image_projection_based_fusion lidar_apollo_instance_segmentation lidar_apollo_segmentation_tvm lidar_apollo_segmentation_tvm_nodes lidar_centerpoint livox_tag_filter map_loader map_tf_generator ndt_omp simulator_compatibility_test tier4_traffic_light_rviz_plugin trtexec_vendor tvm_utility velodyne_pointcloud

```

<!-- TOC --><a name="run-a-planning-simulation"></a>
# Run a planning simulation

According to the docs: "Ad hoc simulation is a flexible method for running basic simulations on your local machine, and is the recommended method for anyone new to Autoware.", but there are no docs on how to do run an ad hoc simulation, so I am going to try a planning simulation based on the [planning simulation docs](https://autowarefoundation.github.io/autoware-documentation/main/tutorials/ad-hoc-simulation/planning-simulation/)

<!-- TOC --><a name="install-the-gdown-utility"></a>
## Install the gdown utility

This tool is needed to download the map data.

```
pip3 install gdown
```

<!-- TOC --><a name="download-maps"></a>
## Download maps

In the container started above:

```

gdown -O ~/autoware_map/ 'https://docs.google.com/uc?export=download&id=1499_nsbUbIeturZaDj7jhUownh5fvXHd'
unzip -d ~/autoware_map ~/autoware_map/sample-map-planning.zip
```

<!-- TOC --><a name="launch-autoware-take-1"></a>
## Launch autoware - take 1

From inside the container:

```
source ~/autoware/install/setup.bash
ros2 launch autoware_launch planning_simulator.launch.xml map_path:=$HOME/autoware_map/sample-map-planning vehicle_model:=sample_vehicle sensor_model:=sample_sensor_kit

```

I'm seeing a ton of errors like:

```
[rviz2-33] [ERROR] [1666308693.487516652] [rviz2]: rviz::RenderSystem: error creating render window: InvalidParametersException: Window with name 'OgreWindow(0)' already exists in GLRenderSystem::_createRenderWindow at /tmp/binarydeb/ros-galactic-rviz-ogre-vendor-8.5.1/.obj-x86_64-linux-gnu/ogre-v1.12.1-prefix/src/ogre-v1.12.1/RenderSystems/GL/src/OgreGLRenderSystem.cpp (line 1061)
```

and red-herring error

```
[component_container_mt-2] [ERROR] [1666308803.727411757] [system.system_monitor.hdd_monitor]: Failed to execute findmnt. /dev/sda3
```

and possible red herring error

```
[system_error_monitor-5] [ERROR] [1666308988.596834579] [system_error_monitor system_error_monitor/input_data_timeout]: [Single Point Fault]: 
```

These issues seem related:

1. https://github.com/autowarefoundation/autoware.universe/issues/630
2. https://github.com/autowarefoundation/autoware.universe/issues/641
3. https://github.com/autowarefoundation/autoware.universe/issues/643


I think this error matters the most, since I get it if I try to launch rviz directly:

```
[rviz2]: InvalidParametersException: Window with name 'OgreWindow(0)' already exists in GLRenderSystem::_createRenderWindow
```

The same error was reported in https://github.com/ros2/rviz/issues/753 and https://github.com/NVIDIA/nvidia-docker/issues/1438.  

I will update my nvidia driver as alluded to above, remove the `-e NVIDIA_DISABLE_REQUIRE=true` workaround, and retry.

<!-- TOC --><a name="upgrade-to-cuda-116"></a>
## Upgrade to CUDA 11.6

I erroneously used the [official nvidia instructions](https://developer.nvidia.com/cuda-11-6-0-download-archive?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=20.04&target_type=deb_local) for installing cuda, so instead use the official [autoware instructions](https://github.com/autowarefoundation/autoware/tree/0423b84ee8d763879bbbf910d249728410b16943/ansible/roles/cuda) to install cuda rather than the steps below.


```
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/11.6.0/local_installers/cuda-repo-ubuntu2004-11-6-local_11.6.0-510.39.01-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2004-11-6-local_11.6.0-510.39.01-1_amd64.deb
sudo apt-key add /var/cuda-repo-ubuntu2004-11-6-local/7fa2af80.pub
sudo apt-get update
sudo apt-get -y install cuda
```

It failed on the last step:

```
# apt-get -y install cuda
Reading package lists... Done
Building dependency tree       
Reading state information... Done
Some packages could not be installed. This may mean that you have
requested an impossible situation or if you are using the unstable
distribution that some required packages have not yet been created
or been moved out of Incoming.
The following information may help to resolve the situation:

The following packages have unmet dependencies:
 cuda : Depends: cuda-11-6 (>= 11.6.0) but it is not going to be installed
E: Unable to correct problems, you have held broken packages.

```

Based on [this advice](https://github.com/autowarefoundation/autoware/discussions/2961#discussioncomment-3929511), I'm going to re-install.  First I am purging:

```
apt-get purge "cuda*" "libcudnn*" "tensorrt*"  "nvidia*"

```

Reboot.

I still had some libnvidia packages, so I purged them with:

```
apt-get purge ~nnvidia
```

Since I'm running a system76 laptop, I went to them for support in order to upgrade the nvidia drivers.

```
apt install system76-driver-nvidia
```

and now I'm running nvidia 515.65.01:

```
# nvidia-smi
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 515.65.01    Driver Version: 515.65.01    CUDA Version: 11.7     |
|-------------------------------+----------------------+----------------------+

```

<!-- TOC --><a name="upgrade-to-cuda-116-take-2"></a>
## Upgrade to CUDA 11.6 - take 2

Again for this step I erroneously used the [official nvidia instructions](https://developer.nvidia.com/cuda-11-6-0-download-archive?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=20.04&target_type=deb_local) for installing cuda, so instead use the official [autoware instructions](https://github.com/autowarefoundation/autoware/tree/0423b84ee8d763879bbbf910d249728410b16943/ansible/roles/cuda) to install cuda rather than the steps below.

```
sudo dpkg -i cuda-repo-ubuntu2004-11-6-local_11.6.0-510.39.01-1_amd64.deb
sudo apt-key add /var/cuda-repo-ubuntu2004-11-6-local/7fa2af80.pub
sudo apt-get update
sudo apt-get -y install cuda
```

This succeeded, but now `nvidia-smi` does not work:

```
$ nvidia-smi
Failed to initialize NVML: Driver/library version mismatch
```

I later realized that I diverged from the autoware instructions in two ways:

1. I should have run ```cuda_version=11-4 apt install cuda-${cuda_version} --no-install-recommends```
2. There are a few post-installation actions that need to be run

Post-installation actions:

```
# Taken from: https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#post-installation-actions
echo 'export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc
```

<!-- TOC --><a name="fixing-nvidia-smi-error"></a>
### Fixing nvidia-smi error

I simply rebooted, and now nvidia-smi works.  Note that the cuda version went from 11.7 to 11.6.  The strange thing is that previously I idn't have the cuda packages installed.

```
$ nvidia-smi
Fri Oct 21 13:56:48 2022       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 510.73.05    Driver Version: 510.73.05    CUDA Version: 11.6     |
|-------------------------------+----------------------+----------------------+

```

<!-- TOC --><a name="start-autoware-docker-container-take-2"></a>
## Start autoware docker container take 2

```
$ rocker --nvidia --x11 --user --volume $HOME/Development/autoware --volume $HOME/Development/autoware_map -- ghcr.io/autowarefoundation/autoware-universe:latest-cuda
```

but got error:

```
docker run --rm -it  --gpus all -v /home/tleyden/Development/autoware:/home/tleyden/Development/autoware -v /home/tleyden/Development/autoware_map:/home/tleyden/Development/autoware_map  -e DISPLAY -e TERM   -e QT_X11_NO_MITSHM=1   -e XAUTHORITY=/tmp/.dockerome5n2bc.xauth -v /tmp/.dockerome5n2bc.xauth:/tmp/.dockerome5n2bc.xauth   -v /tmp/.X11-unix:/tmp/.X11-unix   -v /etc/localtime:/etc/localtime:ro  d0c01d5fe6d7 
docker: Error response from daemon: could not select device driver "" with capabilities: [[gpu]].

```

I realized I'm still missing several requirements:

1. [Nvidia container toolkit](https://github.com/autowarefoundation/autoware/tree/main/ansible/roles/nvidia_docker#manual-installation) - I had this previously, but it was uninstalled.
2. [TensorRT and cuDNN](https://github.com/autowarefoundation/autoware/tree/main/ansible/roles/tensorrt#manual-installation) - ditto

<!-- TOC --><a name="install-nvidia-container-toolkit"></a>
## Install Nvidia container toolkit

I installed nvidia container toolkit based on these [autoware instructions](https://github.com/autowarefoundation/autoware/tree/0423b84ee8d763879bbbf910d249728410b16943/ansible/roles/nvidia_docker#manual-installation)

And now it's able to start a container and run `nvidia-smi`:

```
# docker run --rm --gpus all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi
Fri Oct 21 21:08:28 2022       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 510.73.05    Driver Version: 510.73.05    CUDA Version: 11.6     |
|-------------------------------+----------------------+----------------------+

```

<!-- TOC --><a name="install-cudnn"></a>
## Install cuDNN

```
# apt-get install libcudnn8=${cudnn_version} libcudnn8-dev=${cudnn_version}
Reading package lists... Done
Building dependency tree       
Reading state information... Done
E: Unable to locate package libcudnn8
E: Unable to locate package libcudnn8-dev
```

This error was caused by another divergence from the autoware instructions, where I didn't run [this step](https://github.com/autowarefoundation/autoware/tree/0423b84ee8d763879bbbf910d249728410b16943/ansible/roles/cuda#manual-installation):

```
sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /"
```

I re-ran all of [these steps from the autoware docs](https://github.com/autowarefoundation/autoware/tree/0423b84ee8d763879bbbf910d249728410b16943/ansible/roles/tensorrt):

```
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub
sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /"
sudo apt-get update
```

and now this step worked:

```
apt-get install libcudnn8=${cudnn_version} libcudnn8-dev=${cudnn_version}
```

Pin the libraries at those versions with:

```
sudo apt-mark hold libcudnn8 libcudnn8-dev
```


<!-- TOC --><a name="install-tensorrt"></a>
## Install TensorRT

Using [these instructions](https://github.com/autowarefoundation/autoware/tree/0423b84ee8d763879bbbf910d249728410b16943/ansible/roles/tensorrt):

```
tensorrt_version=8.4.2-1+cuda11.6
sudo apt-get install libnvinfer8=${tensorrt_version} libnvonnxparsers8=${tensorrt_version} libnvparsers8=${tensorrt_version} libnvinfer-plugin8=${tensorrt_version} libnvinfer-dev=${tensorrt_version} libnvonnxparsers-dev=${tensorrt_version} libnvparsers-dev=${tensorrt_version} libnvinfer-plugin-dev=${tensorrt_version}
sudo apt-mark hold libnvinfer8 libnvonnxparsers8 libnvparsers8 libnvinfer-plugin8 libnvinfer-dev libnvonnxparsers-dev libnvparsers-dev libnvinfer-plugin-dev
```

<!-- TOC --><a name="start-autoware-docker-container-take-3"></a>
## Start autoware docker container take 3

```
$ rocker --nvidia --x11 --user --volume $HOME/Development/autoware --volume $HOME/Development/autoware_map -- ghcr.io/autowarefoundation/autoware-universe:latest-cuda
tleyden@apollo:~$ rocker --nvidia --x11 --user --volume $HOME/Development/autoware --volume $HOME/Development/autoware_map -- ghcr.io/autowarefoundation/autoware-universe:latest-cuda
Extension volume doesn't support default arguments. Please extend it.
Active extensions ['nvidia', 'volume', 'x11', 'user']
Step 1/12 : FROM python:3-slim-stretch as detector
...
Executing command:
docker run --rm -it  --gpus all -v /home/tleyden/Development/autoware:/home/tleyden/Development/autoware -v /home/tleyden/Development/autoware_map:/home/tleyden/Development/autoware_map  -e DISPLAY -e TERM   -e QT_X11_NO_MITSHM=1   -e XAUTHORITY=/tmp/.docker77n9jx85.xauth -v /tmp/.docker77n9jx85.xauth:/tmp/.docker77n9jx85.xauth   -v /tmp/.X11-unix:/tmp/.X11-unix   -v /etc/localtime:/etc/localtime:ro  d0c01d5fe6d7
tleyden@0b1ce9ed54bd:~$
```

This worked, but at first I was very confused that it actually worked.

It drops you back at the prompt with no meaningful output, but if you look closely, **it's a different prompt**.  The hostname changes from your actual hostname (apollo in my case), to this cryptic container name (`0b1ce9ed54bd`).

Note that if you run this in the container:

```
$ ros2 topic list
/parameter_events
/rosout
```

you will see meaningful output, whereas if you run that on your host, you will most likely see `ros2: command not found`, unless you had installed `ros2` on your host previously.


<!-- TOC --><a name="launch-autoware-take-2"></a>
## Launch autoware take 2

(also requires maps download, see above)


From inside the container:

```
source ~/autoware/install/setup.bash
ros2 launch autoware_launch planning_simulator.launch.xml map_path:=$HOME/autoware_map/sample-map-planning vehicle_model:=sample_vehicle sensor_model:=sample_sensor_kit

```

But the same errors are showing up:

```
[rviz2-33] libGL error: MESA-LOADER: failed to retrieve device information
[rviz2-33] libGL error: MESA-LOADER: failed to retrieve device information
[rviz2-33] [ERROR] [1666388259.903611735] [rviz2]: RenderingAPIException: OpenGL 1.5 is not supported in GLRenderSystem::initialiseContext at /tmp/binarydeb/ros-galactic-rviz-ogre-vendor-8.5.1/.obj-x86_64-linux-gnu/ogre-v1.12.1-prefix/src/ogre-v1.12.1/RenderSystems/GL/src/OgreGLRenderSystem.cpp (line 1201)
[rviz2-33] [ERROR] [1666388259.905397712] [rviz2]: rviz::RenderSystem: error creating render window: RenderingAPIException: OpenGL 1.5 is not supported in GLRenderSystem::initialiseContext at /tmp/binarydeb/ros-galactic-rviz-ogre-vendor-8.5.1/.obj-x86_64-linux-gnu/ogre-v1.12.1-prefix/src/ogre-v1.12.1/RenderSystems/GL/src/OgreGLRenderSystem.cpp (line 1201)

```

[Full output log](https://gist.github.com/tleyden/64a84ca4316c95ca9daa0c8d73728ac1)

Note that these errors are also shown if I run `rviz2` from within the container.

```
$ rviz2
QStandardPaths: XDG_RUNTIME_DIR not set, defaulting to '/tmp/runtime-tleyden'
libGL error: MESA-LOADER: failed to retrieve device information
libGL error: MESA-LOADER: failed to retrieve device information
[ERROR] [1666389050.804997231] [rviz2]: RenderingAPIException: OpenGL 1.5 is not supported in GLRenderSystem::initialiseContext at /tmp/binarydeb/ros-galactic-rviz-ogre-vendor-8.5.1/.obj-x86_64-linux-gnu/ogre-v1.12.1-prefix/src/ogre-v1.12.1/RenderSystems/GL/src/OgreGLRenderSystem.cpp (line 1201)
[ERROR] [1666389050.805238544] [rviz2]: rviz::RenderSystem: error creating render window: RenderingAPIException: OpenGL 1.5 is not supported in GLRenderSystem::initialiseContext at /tmp/binarydeb/ros-galactic-rviz-ogre-vendor-8.5.1/.obj-x86_64-linux-gnu/ogre-v1.12.1-prefix/src/ogre-v1.12.1/RenderSystems/GL/src/OgreGLRenderSystem.cpp (line 1201)
[ERROR] [1666389050.805275164] [rviz2]: InvalidParametersException: Window with name 'OgreWindow(0)' already exists in GLRenderSystem::_createRenderWindow at /tmp/binarydeb/ros-galactic-rviz-ogre-vendor-8.5.1/.obj-x86_64-linux-gnu/ogre-v1.12.1-prefix/src/ogre-v1.12.1/RenderSystems/GL/src/OgreGLRenderSystem.cpp (line 1061)
```

<!-- TOC --><a name="fix-rviz2-errors"></a>
### Workaround rviz2 errors by passing in /dev/dri device

Relevant github issues:

1. https://github.com/ros2/rviz/issues/672
2. https://github.com/openai/gym/issues/509

The recommended fix is:

```
apt-get install -y mesa-utils libgl1-mesa-glx
```

I don't currently have either of those libraries installed:

```
dpkg -l | grep -i "mesa-utils"
dpkg -l | grep -i "libgl1-mesa-glx"

```

I installed these packages on the host (outside the container), but that didn't fix the issue.

I tried installing the packages in the container, but that didn't work either.

There is a discrepancy between `glxinfo` on the host vs container. 

In this container:


```
$ rocker --nvidia --x11 --user nvidia/cuda:11.0.3-base-ubuntu20.04
```

It is returning an error:

```
$ apt update && apt install -y mesa-utils
$ glxinfo -B
name of display: :1
libGL error: MESA-LOADER: failed to retrieve device information
display: :1  screen: 0
direct rendering: Yes
Extended renderer info (GLX_MESA_query_renderer):
    Vendor: Intel Open Source Technology Center (0x8086)
    Device: Mesa DRI Unknown Intel Chipset  (0x3e9b)
    Version: 21.2.6
    Accelerated: yes
    Video memory: 3072MB
    Unified memory: yes
    Preferred profile: compat (0x2)
    Max core profile version: 0.0
    Max compat profile version: 1.3
    Max GLES1 profile version: 1.1
    Max GLES[23] profile version: 0.0
OpenGL vendor string: Intel Open Source Technology Center
OpenGL renderer string: Mesa DRI Unknown Intel Chipset 
OpenGL version string: 1.3 Mesa 21.2.6

```

Whereas on the host:

```
$ glxinfo -B
name of display: :1
display: :1  screen: 0
direct rendering: Yes
Extended renderer info (GLX_MESA_query_renderer):
    Vendor: Intel (0x8086)
    Device: Mesa Intel(R) UHD Graphics 630 (CFL GT2) (0x3e9b)
    Version: 21.2.2
    Accelerated: yes
    Video memory: 3072MB
    Unified memory: yes
    Preferred profile: core (0x1)
    Max core profile version: 4.6
    Max compat profile version: 4.6
    Max GLES1 profile version: 1.1
    Max GLES[23] profile version: 3.2
OpenGL vendor string: Intel
OpenGL renderer string: Mesa Intel(R) UHD Graphics 630 (CFL GT2)
OpenGL core profile version string: 4.6 (Core Profile) Mesa 21.2.2
OpenGL core profile shading language version string: 4.60
OpenGL core profile context flags: (none)
OpenGL core profile profile mask: core profile

OpenGL version string: 4.6 (Compatibility Profile) Mesa 21.2.2
OpenGL shading language version string: 4.60
OpenGL context flags: (none)
OpenGL profile mask: compatibility profile

OpenGL ES profile version string: OpenGL ES 3.2 Mesa 21.2.2
OpenGL ES profile shading language version string: OpenGL ES GLSL ES 3.20

```

This [stack overflow post](https://stackoverflow.com/questions/45136499/how-do-i-pass-data-info-about-the-gpu-versions-of-opengl-opencl-mesa-etc) suggested a workaround, and according to the [rocker docs](https://github.com/osrf/rocker) 

"For Intel integrated graphics support you will need to mount the /dev/dri directory as follows:"

```
--devices /dev/dri
```

After restarting a container with that flag, it no longer shows the `libGL error: MESA-LOADER: failed to retrieve device information` error.

I [posted a question](https://github.com/autowarefoundation/autoware/discussions/2965) on the autoware forum to find out why this workaround was needed.  Apparently there is another way to solve this problem by forcing the use of the nvidia gpu rather than the intel graphics card:

```
prime-select query
# It should show on-demand by default
sudo prime-select nvidia
# Force to use NVIDIA GPU
```

but I haven't verified this yet.


<!-- TOC --><a name="start-autoware-docker-container-take-4"></a>
## Start autoware docker container take 4

Add the `--devices /dev/dri` flag:

```
$ rocker --nvidia --x11 --devices /dev/dri --user --volume $HOME/Development/autoware --volume $HOME/Development/autoware_map -- ghcr.io/autowarefoundation/autoware-universe:latest-cuda
```

And now it finally works!! Running `rviz2` from within the container shows the rviz window:


![Screenshot from 2022-10-21 15-44-48](https://user-images.githubusercontent.com/296876/197299394-a1dcd275-4115-418c-9641-a4de762cf826.png)


<!-- TOC --><a name="launch-autoware-take-3"></a>
## Launch autoware take 3

(also requires maps download, see above)


From inside the container:

```
source ~/autoware/install/setup.bash
ros2 launch autoware_launch planning_simulator.launch.xml map_path:=$HOME/autoware_map/sample-map-planning vehicle_model:=sample_vehicle sensor_model:=sample_sensor_kit

```

and rviz launched with autoware configured:

![Screenshot from 2022-10-21 15-51-01](https://user-images.githubusercontent.com/296876/197301286-7e8b257e-0587-4fa1-ab54-ed5be4f0cfcd.png)

Phew!  That was a lot harder than I thought it was going to be!  It would have gone smoother if:

* My nvidia/cuda drivers were up-to-date with Cuda 11.6 and a suitable nvidia driver version.
* I'd followed the autoware docs rather than using the nvidia docs - the small divergences mattered a lot. (:facepalm)
* I had known about the `--devices /dev/dri` or nvidia "prime-select" workarounds.  


<!-- TOC --><a name="references"></a>
# References

* [Official autoware installation guide](https://autowarefoundation.github.io/autoware-documentation/main/installation/)

