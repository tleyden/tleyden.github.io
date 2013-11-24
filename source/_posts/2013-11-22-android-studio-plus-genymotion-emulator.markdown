---
layout: post
title: "Android Studio + Genymotion Emulator"
date: 2013-11-22 15:51
comments: true
categories: [android]
---

The Android emulator is dog slow.  The x86 intel emulators only work with certain versions of OSX, otherwise they crash miserably.

Genymotion is apparently pretty good, so I'm giving that a shot.

Here's how to do it.

## Download and Install VirtualBox

[Download VirtualBox](https://www.virtualbox.org/wiki/Downloads) + follow instructions to install.

## Signup with Genymotion + Download installer

* Go to [genymotion.com](genymotion.com) and signup

* Click the "Get Genymotion" button and [download](https://cloud.genymotion.com/page/launchpad/download/) the appropriate version for your OS.

## Run the Genymotion application

It will install Genymotion and Genmotion shell -- run the Genymotion application (not the shell).

When you run it, you will see:

![Screenshot](http://cl.ly/image/0e1j3t1j1V3F/Screen%20Shot%202013-11-22%20at%203.57.11%20PM.png)

Click add new virtual device.  It will ask you to login, then show you a list:

![Screenshot](http://cl.ly/image/2i3M2D0p2M2J/Screen%20Shot%202013-11-22%20at%203.59.41%20PM.png)

Pick the virtual device you want and it will download it.

## Try starting a virtual device

Here's what happened on my system:

* Hit Play to run virtual device
* It asked me to configure the Android SDK location, I said "No"
* Then it gave me an error that VirtualBox was not installed
* I started VirtualBox manually
* I retried running the virtual device, this time it worked and I saw

![Screenshot](http://cl.ly/image/252a1T3d2U1x/Screen%20Shot%202013-11-22%20at%204.06.46%20PM.png)

## Configure Android Studio plugin

Go to Preferences / Plugins and click "Browse Repositories", then search for Genymotion.  Right click and choose "Download and Install".

![Screenshot](http://cl.ly/image/110z2N2i1S3N/Screen%20Shot%202013-11-22%20at%204.08.42%20PM.png)

Restart Android Studio and you should see a new icon in your IDE.

![Screenshot](http://cl.ly/image/0F0N330u0C32/Screen%20Shot%202013-11-22%20at%204.11.00%20PM.png)

Click the icon and it will bring up Preferences, and choose the path to the Genymotion application.

![Screenshot](http://cl.ly/image/3G3K1s0p2h3x/Screen%20Shot%202013-11-22%20at%204.14.05%20PM.png)

Now if you click the Genymotion icon again, you will see the list of devices available:

![Screenshot](http://cl.ly/image/1Y120s1n1d2l/Screen%20Shot%202013-11-22%20at%204.15.20%20PM.png)

## Start an emulator

Click the Genymotion icon within Android studio, select a virtual device, and hit start.

It will ask you to choose the location of the SDK:

![Screenshot](http://cl.ly/image/2N0W1h0O3Q2H/Screen%20Shot%202013-11-22%20at%204.18.02%20PM.png)

On Mac OSX, I was not able to brows to the path since the application was greyed out in the chooser dialog, so I went onto the shell and found it (/Applications/Android Studio.app/sdk) and just copied and pasted it:

![Screenshot](http://cl.ly/image/2V2H0d0M1z0f/Screen%20Shot%202013-11-22%20at%204.21.12%20PM.png)

Select a virtual device, and hit start (again).  It should come up now.

## Deploy an application/test to that emulator

In Android Studio, hit the "Play" or "Debug" button, and you should see the dialog that asks you to choose an emulator:

![Screenshot](http://cl.ly/image/1I43000V3h12/Screen%20Shot%202013-11-22%20at%204.25.21%20PM.png)

and one of the emulators will be the Genymotion emulator.  After you choose that emulator and hit "OK", it will run your application in the Genymotion emulator (this is showing the [Grocery Sync](https://github.com/couchbaselabs/GrocerySync-Android) demo app for [Couchbase Lite](https://github.com/couchbase/couchbase-lite-android)):

![Screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/Genymotion_Grocery_sync.png)






