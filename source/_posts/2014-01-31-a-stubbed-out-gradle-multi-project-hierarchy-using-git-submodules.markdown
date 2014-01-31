---
layout: post
title: "A stubbed out gradle multi-project hierarchy using git submodules"
date: 2014-01-31 10:50
comments: true
categories: 
---

I'm about to split up the [couchbase-lite](https://github.com/couchbase/couchbase-lite-android) android library into two parts: a pure-java and an android specific library.  The android library will depend on the pure-java library.

Before going down this project refactoring rabbit hole for the real project, I decided to stub out a complete project hierarchy to validate that it was going to actually work.  (I'm calling this project hierarchy "stubworld" for lack of a sillier name)  

There are five projects in total, here are the two top-level projects

https://github.com/tleyden/stubworld-app-android  (an Android app)

![](http://cl.ly/image/3O31321l0b0n/stubworld_architecture_android.png)

https://github.com/tleyden/stubworld-app-cmdline  (a pure java Command Line application)

![](http://cl.ly/image/1M2C333S2s0u/stubworld_architecture_desktop.png)

The projects are all self contained gradle projects and can be imported in either Android Studio or IntelliJ CE 13, and the dependencies on lower level projects are done via git submodules (and even git sub-submodules, *gulp*).   In either top level project you can easily debug and edit the code in the lower level projects, since they use source level dependencies.

The biggest sticking point I ran into was that initially I tried to include a dependency via:

```
compile project(':libraries:stubworld-corelib-java')
```

which totally broke when trying to embed this project into another parent project. The fix was to change it to use a relative path by removing the leading colon:

```
compile project('libraries:stubworld-corelib-java')
```

I'm posting this in case it's useful to anyone who needs to do something similar, or if any Gradle / Android Studio Jedi masters have any feedback like "why did you do X, when you just could have done Y?"