---
layout: post
title: "Debugging into Apache HttpClient on Android"
date: 2014-09-10 16:47
comments: true
categories: android, androidstudio
---

If you are using the "default" Apache httpclient that ships with Android, trying to debug into these classes won't work, and you'll see this:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/cant_debug_httpclient.png)

According to [this Stack Overflow post](http://stackoverflow.com/questions/2618573/what-version-of-apache-http-client-is-bundled-in-android-1-6/4818714#4818714), it uses httpcore-4.0-beta2.jar and httpclient-4.0-beta1.jar.

In my case, I already have those libs in my libs directory, as well as the following in my build.gradle file:

```
compile fileTree(dir: 'libs', include: '*.jar')
```

Download the corresponding source libs for httpcore-4.0-beta2.jar and httpclient-4.0-beta1.jar into your libs directory:

* [httpcore-4.0-beta2.jar](http://repo1.maven.org/maven2/org/apache/httpcomponents/httpcore/4.0-beta2/httpcore-4.0-beta2-sources.jar)
* [httpclient-4.0-beta1.jar](http://repo1.maven.org/maven2/org/apache/httpcomponents/httpclient/4.0-beta1/httpclient-4.0-beta1-sources.jar)

# Stepping in didn't work for me, so set an explicit breakpoint

In my case, the code was calling:

```
httpClient.execute(this.request);
```

where `httpClient` was an instance of an `org.apache.http.impl.client.DefaultHttpClient`.  Stepping into that method did **not** work.

As a workaround, manually navigate the libs/httpclient-4.0-beta1-sources.jar to org.apache.http.impl.client.AbstractHttpClient, and set a breakpoint in the appropriate `execute()` method:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/manual_httpclient_breakpoint.png)

Now when you run your code, that breakpoint should be hit and you can debug.
