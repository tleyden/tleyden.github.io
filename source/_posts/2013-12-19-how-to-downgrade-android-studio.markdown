---
layout: post
title: "How to downgrade Android Studio"
date: 2013-12-19 17:01
comments: true
categories: 
---

I just tried to update to Android Studio 0.4, however was stung by [Issue 61573: Gradle duplicate file exception when package apk file with jar dependencies that contains resources.](https://code.google.com/p/android/issues/detail?id=61573#c14)

The good news is that it's very easy to downgrade!  Thank Google, because there is nothing more annoying than not being able to back out of an upgrade gone bad.

Here's how I did it on OSX Mavericks:

* Download 0.3.7 from http://tools.android.com/download/studio/canary/0-3-7

* Unzip it by double clicking it.

* In a command line, run the following:

```
$ mv /Applications/Android\ Studio.app /tmp/
$ mv ~/Downloads/Android\ Studio.app /Applications/
$ cp -R /tmp/Android\ Studio.app/sdk /Applications/Android\ Studio.app/
```

The last step is necessary because the dowloaded 0.3.7 Android Studio will not have an SDK directory.  (Note: at this point you can also use `mv` instead of `cp` if you don't want to use the extra disk space)
