---
layout: post
title: "Debugging HTTP traffic in Android apps with a proxy"
date: 2013-11-20 14:35
comments: true
categories: [android]
---

If you need to debug the HTTP communication between a server and an Android app running in an emulator or device, here's some instructions on how I went about doing it.

Here's the overall diagram of what's happening:

![Diagram](http://tleyden-misc.s3.amazonaws.com/blog_images/android_proxy.png)

## Install a Proxy

I'm using [Charles Proxy](http://www.charlesproxy.com/) and highly recommend it. 

As far as proxy configuration, the defaults should be fine.  It should be listening on port 8888 and proxying everything.  If you need HTTPS, you might have to configure that, I don't remember if it's enabled by default.

## Configure the Android Emulator to use that proxy

There is a blog that describes how to get to this screen, I don't have the link handy.  Essentially once you get to this screen, just update the ip to have the special 10.0.2.2 ip address which represents your workstation, and the port the proxy is listening on (port 8888).

![Screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/android_emu_proxy_config.png)

## Run an HTTP server on your workstation, on port 4984

Actually use any port you want, but in my case I'm connecting to a server that runs on port 4984.

## Configure your app to connect to 127.0.0.1:4984

This is actually a bit counterintuitive, but the idea is that the address must be reachable from the workstation's network, not from the emulator's network.

So for that reason, if the server is running on the workstation, you would want to use 127.0.0.1 as the IP.

As long as the server is reachable from your workstation, you can use that IP and it will go through the proxy.

## View HTTP traffic in proxy

Here's what the HTTP JSON response looks like in the proxy:

![Screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/charles_proxy_screenshot.png)

## If you are using the Genymotion emulator

The Genymotion emulator has a different method of modifying the proxy setting:

In your virtual device:

* Go to Android settings menu
* In Wireless & Networks section, select Wi-Fi
* Press and hold for 2 seconds WiredSSID network in the list
* Choose Modify Network
* Check Show advanced options
* Select Manual for Proxy settings menu entry
* Now enter the proxy settings provided by your network administrator
  * Ip: 10.0.3.2 (this is a special ip that Genymotion uses to connect back to the host)
  * Port: 8888
* Finally press the Save button

If you don't have Genymotion running, you should check it out, it runs _much_ faster than the default emulator.  [How to get Android Studio + Genymotion working](http://tleyden.github.io/blog/2013/11/22/android-studio-plus-genymotion-emulator/)