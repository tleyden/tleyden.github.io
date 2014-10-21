---
layout: post
title: "Debugging into Android source"
date: 2014-09-10 15:57
comments: true
categories: android, androidstudio
---

Debugging into the core Android source code can be useful.  Here's how to do it in Android Studio 0.8.2.

Starting out, if we hit a breakpoint where we have a sqlite database object:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/outside_db_breakpoint.png)

And if you step in, you get this, which isn't very useful:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/inside_db_breakpoint.png)

To fix that, go to Android SDK, find the API level you are using, and check the Sources for Android SDK box.

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/android_sdk.png)

**You must restart Android Studio at this point**

Did you restart Android Studio?  Now re-run your app in the debugger, and when you try to step into the `database.execSQL()` method, you should see this:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/db_source_breakpoint.png)

It worked!  Now you can debug into any Android code.


