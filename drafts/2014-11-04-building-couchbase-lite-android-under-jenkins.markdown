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
sudo apt-get update && sudo apt-get install -y openjdk-7-jre openjdk-7-jdk git gcc-multilib lib32z1 lib32stdc++6
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

## Git plugin

**Install**

* Go to Manage Jenkins / Manage Plugins and click "Available" tab
* Search for "Git plugin" + install it 

**Configure**

* Repository URL: https://github.com/couchbase/couchbase-lite-android
* Add Additional Behavior: Recursively update submodules

## Install Android SDK

The Android Emulator plugin expects to find the android-sdk in `/var/lib/jenkins/tools`, so install it there.

```
cd /var/lib/jenkins/tools
wget http://dl.google.com/android/android-sdk_r23.0.2-linux.tgz
tar xvfz android-sdk_r23.0.2-linux.tgz
mv android-sdk-linux android-sdk
```

**Add environment variables**

Run `vi /etc/profile.d/android.sh` and add:

```
export ANDROID_HOME="/var/lib/jenkins/tools/android-sdk"
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
sudo chmod -R 755 /var/lib/jenkins/tools/android-sdk
```

## Add build exec task

```
cat local.properties.example | sed 's/\/Applications\/Android Studio.app\/sdk/\/var\/lib\/jenkins\/tools\/android-sdk/g' > local.properties
cp settings.gradle.example settings.gradle
./gradlew buildassembleDebugTest
```

## Install and Configure AppThwack

**Install Jenkins AppThwack plugin**

It is available from the Jenkins plugin manager

**Configure AppThwack**

* In Manage Jenkins / Configure, add your AppThwack Api key
* In the Jenkins job config, add a new post-build action
* Choose Run Tests on AppThwack
* Hit "Refresh" button to pull latest settings from AppThwack
* Choose Project and Device Pool
* Under Application, enter `**/build/outputs/apk/couchbase-lite-android-debug-test-unaligned.apk`
* Under "Choose tests to run", click ( ) JUnit/Robotium/Espresso
* For **Tests** enter: `**/build/outputs/apk/couchbase-lite-android-debug-test-unaligned.apk`


## References

* http://blog.appthwack.com/continuous-integration-for-mobile-apps/
* https://www.digitalocean.com/community/tutorials/how-to-build-android-apps-with-jenkins
* https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Ubuntu
* http://stackoverflow.com/questions/22333041/android-emulator-plugin-failed-to-initialize-backend-egl-display
* http://stackoverflow.com/questions/17020298/android-sdks-build-tools-17-0-0-aapt-error-while-loading-shared-libraries-libz
* http://askubuntu.com/questions/147400/problems-with-eclipse-and-android-sdk
* http://stackoverflow.com/questions/15590239/emulator-warning-could-not-initialize-opengles-emulation-using-software-rende