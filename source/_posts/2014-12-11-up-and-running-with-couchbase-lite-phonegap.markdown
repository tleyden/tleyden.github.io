---
layout: post
title: "Up and Running with Couchbase Lite Phonegap Android on OSX"
date: 2014-12-11 12:48
comments: true
categories: couchbase-lite, mobile
---

This will walk you through the steps to install the TodoLite-Phonegap sample app that uses Couchbase Lite Android.  After you're finished, you'll end up with [this app](http://tleyden-misc.s3.amazonaws.com/blog_images/TodoLitePhonegap.png).

# Install Homebrew

* Install [homebrew](http://brew.sh/)

## Install Android Studio 

* Install [Android Studio 1.0](https://developer.android.com/sdk/index.html) 

* Setup an AVD + emulator -- in my case I'm using the [Genymotion emulator](https://www.genymotion.com/), with a Google Nexus 4 - 4.4.4 API 19

* At this point you should verify your setup by deploying [TodoLite-Android](https://github.com/couchbaselabs/ToDoLite-Android) to your emulator

# Install Phonegap

## Install Node.js

Phonegap is installed with the Node Package Manager (npm), so we need to get Node.js first.

```
brew install node
```

## Install Phonegap

```
$ sudo npm install -g phonegap
```

You should see [this output](https://gist.github.com/tleyden/94bf77d084fa9a6cca0c)

Check your version with:

```
$ phonegap -v
4.1.2-0.22.9
```

## Install Ant

```
$ brew install ant
```

Check your Ant version with:

```
$ ant -version
Apache Ant(TM) version 1.9.4 compiled on April 29 2014
```

*Note: according to [Stack Overflow](http://superuser.com/questions/610157/how-do-i-install-ant-on-os-x-mavericks) you may have to install XCode and the Command Line Tools for this to work*

## Create new Phonegap App

```
$ phonegap create todo-lite com.couchbase.TodoLite TodoLite

```

You should see the following output:

    Creating a new cordova project with name "TodoLite" and id "com.couchbase.TodoLite" at location "/Users/tleyden/Development/todo-lite"
    Using custom www assets from https://github.com/phonegap/phonegap-app-hello-world/archive/master.tar.gz
    Downloading com.phonegap.hello-world library for www...
    Download complete

cd into the newly created directory:

```
$ cd todo-lite
```

## Add the Couchbase Lite plugin

```
$ phonegap local plugin add https://github.com/couchbaselabs/Couchbase-Lite-PhoneGap-Plugin.git
```

You should see the following output:

    [warning] The command `phonegap local <command>` has been DEPRECATED.
    [warning] The command has been delegated to `phonegap <command>`.
    [warning] The command `phonegap local <command>` will soon be removed.
    Fetching plugin "https://github.com/couchbaselabs/Couchbase-Lite-PhoneGap-Plugin.git" via git clone

## Add additional plugins required by TodoLite-Phonegap

```
$ phonegap local plugin add https://git-wip-us.apache.org/repos/asf/cordova-plugin-camera.git
$ phonegap local plugin add https://github.com/apache/cordova-plugin-inappbrowser.git 
$ phonegap local plugin add https://git-wip-us.apache.org/repos/asf/cordova-plugin-network-information.git
```

## Clone the example app source code

```
$ rm -rf www
$ git clone https://github.com/couchbaselabs/TodoLite-PhoneGap.git www
```

# Verify ANDROID_HOME environment variable

If you don't already have it set, you will need to set your ANDROID_HOME environment variable:

```
$ export ANDROID_HOME="/Applications/Android Studio.app/sdk"
$ export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

## Run app

```
$ phonegap run android
```

You should see the following output:

    [phonegap] executing 'cordova platform add android'...
    [phonegap] completed 'cordova platform add android'
    [phonegap] executing 'cordova run android'...
    [phonegap] completed 'cordova run android'


## Verify app 

TodoLite-Phonegap should launch on the emulator and look like this:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/TodoLitePhonegap.png)

## Facebook login

Hit the happy face in the top right, and it will prompt you to login via Facebook.

![Screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/TodoLitePhoneGapFacebook.png)

## View data

After logging in, it will sync any data for your user stored on the Couchbase Mobile [demo cluster](https://github.com/couchbaselabs/TodoLite-PhoneGap/blob/aa8bc5a6b35ce8d49ec089ec79952f1a50e207a2/js/index.js#L30).  

For example, if you've previously used [TodoLite-iOS](https://github.com/couchbaselabs/ToDoLite-iOS) or [TodoLite-Android](https://github.com/couchbaselabs/ToDoLite-Android), your data should appear here.

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/TodoLitePhoneGapData.png)

## Test Sync via single device

* Login with Facebook as described above
* Add a new Todo List
* Add an item to your Todo List
* Uninstall the app
* Re-install the app by running `phonegap run android` again
* Login with Facebook
* Your Todo List and item added above should now appear

## Test Sync via 2 apps

* Install [TodoLite-Android](https://github.com/couchbaselabs/ToDoLite-Android)
* Login with Facebook
* Add / edit / delete items on [TodoLite-Android](https://github.com/couchbaselabs/ToDoLite-Android)
* Verify the changes appear in TodoLite-Phonegap

*Note: you could also setup two emulators and run the apps separately*

## Appendix A: using a more recent build of the Phonegap Plugin

## Reset state

```
$ cd .. 
$ rm -rf todo-lite
```

## Create another phonegap app

```
$ phonegap create todo-lite com.couchbase.TodoLite TodoLite
$ cd todo-lite
```

## Download zip file

```
$ mkdir Couchbase-Lite-PhoneGap-Plugin && cd Couchbase-Lite-PhoneGap-Plugin
$ wget http://cbfs-ext.hq.couchbase.com/builds/Couchbase-Lite-PhoneGap-Plugin_1.0.4-41.zip
$ unzip Couchbase-Lite-PhoneGap-Plugin_1.0.4-41.zip
```

## Add local plugin

```
$ phonegap local plugin add Couchbase-Lite-PhoneGap-Plugin
```

You should see output:

 [warning] The command `phonegap local <command>` has been DEPRECATED.
 [warning] The command has been delegated to `phonegap <command>`.
 [warning] The command `phonegap local <command>` will soon be removed.

Now just follow the rest of the steps above ..

# References

* http://developer.couchbase.com/mobile/get-started/get-started-mobile/phonegap/prepare/index.html
