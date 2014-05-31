---
layout: post
title: "Docker on OSX"
date: 2013-11-12 21:01
comments: true
categories: [docker]
---

![Docker.png](http://cl.ly/image/302X103n330L/docker.png)

# Goal

Get Docker running under OSX.

## Environment

* OSX Mavericks

* Macbook Retina

## Understanding the tools

* Vagrant is a tool to provision VMs.  
* Virtualbox is VM software.  
* CoreOS is an operating system based on linux that's all about running docker.

## Install VirtualBox + Vagrant

* Install VirtualBox via [VirtualBox OSX installer](http://download.virtualbox.org/virtualbox/4.3.2/VirtualBox-4.3.2-90405-OSX.dmg)

* Install Vagrant via [Vagrant OSX installer](https://dl.bintray.com/mitchellh/vagrant/vagrant_1.6.2.dmg)

## Vagrant Smoke Test: run Ubuntu Precise

To make sure Vagrant is installed correctly, run the following commands to see if Ubuntu Precise comes up and you are able to ssh into it.

```
vagrant init precise32 http://files.vagrantup.com/precise32.box
vagrant up
vagrant ssh
```

If that doesn't work, you should probably fix it before moving on.  Otherwise, keep reading.

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

After running this, you should be ssh'd inside of an Ubuntu shell, running under docker (running inside of VirtualBox .. etc, all the way up the onion)