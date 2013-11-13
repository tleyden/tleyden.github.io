---
layout: post
title: "Docker on OSX"
date: 2013-11-12 21:01
comments: true
categories: 
---

![Docker.png](http://cl.ly/image/302X103n330L/docker.png)

# Goal

I want to get Docker running under OSX.

## Environment

* OSX Mavericks

* Macbook Retina

## Understanding the tools

* Vagrant is a tool to provision VMs.  
* Virtualbox is VM software.  
* CoreOS is an operating system based on linux that's all about running docker.

## Install VirutalBox + Vagrant

* Install VirtualBox via [VirtualBox OSX installer](http://download.virtualbox.org/virtualbox/4.3.2/VirtualBox-4.3.2-90405-OSX.dmg)

* Install Vagrant via [Vagrant OSX installer](http://files.vagrantup.com/packages/a40522f5fabccb9ddabad03d836e120ff5d14093/Vagrant-1.3.5.dmg)

## Vagrant Up

```
vagrant init precise32 http://files.vagrantup.com/precise32.box
vagrant up
```

## Install/Run CoreOS

```
git clone https://github.com/coreos/coreos-vagrant/
cd coreos-vagrant
vagrant up
```

## SSH into CoreOS

```
vagrant ssh
```

## Run stock ubuntu docker image

```
docker run -t -i ubuntu bash
```

After running this, you should be ssh'd inside of an Ubuntu shell, running under docker (running inside of VirtualBox)