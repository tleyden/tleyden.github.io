---
layout: post
title: "Building Couchbase Lite Android under Jenkins"
date: 2014-11-04 17:07
comments: true
categories: jenkins couchbase-lite
---

## Launch Ubuntu 14.04 in AWS

* AMI: ubuntu-trusty-14.04-amd64-server-20140927 (ami-98aa1cf0)
* Root device type: ebs
* Instance type: m3.medium
* Network: Ec2-classic
* Virtualization type: paravirtual

**Note**: you will also probably want to open up port 8080 in your security group to all ip addresses, in order to access it from outside AWS.

## Install dependencies

```
sudo apt-get update && sudo apt-get install -y openjdk-7-jre openjdk-7-jdk git gcc-multilib
```

## Install Jenkins

```
wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get -y install jenkins
```

## Verify Jenkins is running

```
curl localhost:8080
```

and you should see some HTML returned.

## Install git plugin

* Go to Manage Jenkins / Manage Plugins
* Click "Available" tab
* Search for "Git plugin"
* Install it 

## Install Android SDK

See https://www.digitalocean.com/community/tutorials/how-to-build-android-apps-with-jenkins

```
cd /opt
wget http://dl.google.com/android/android-sdk_r23.0.2-linux.tgz
tar xvfz android-sdk_r23.0.2-linux.tgz
```

**Add environment variables**

Run `vi /etc/profile.d/android.sh` and add:

```
export ANDROID_HOME="/opt/android-sdk-linux"
export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH"
```

And then reload the file with: `source /etc/profile`


## Configure Android SDK

```
android update sdk -u --filter platform-tools,android-19
```

**Install build tools**

```
android list sdk --all | grep -i build
```

and look for:

`9- Android SDK Build-tools, revision 19.1`

Now install by number:

```
android update sdk -u --all --filter 8
```

**Make Android SDK accessible by Jenkins**

```
sudo chmod -R 755 /opt/android-sdk-linux
```

## References

* https://www.digitalocean.com/community/tutorials/how-to-build-android-apps-with-jenkins
* https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Ubuntu