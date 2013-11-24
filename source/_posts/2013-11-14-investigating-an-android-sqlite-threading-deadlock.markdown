---
layout: post
title: "Investigating an Android SQLite threading deadlock"
date: 2013-11-14 11:24
comments: true
categories: [android, java]
---

In an unreleased version of Couchbase Lite for Android, I was seeing the following error:

```
SQLiteConnectionPool The connection pool for database has been unable to grant a connection to thread
SQLiteConnectionPool(14004): Connections: 0 active, 1 idle, 0 available.
```

## Here's what turned out to be happening

![Diagram](http://cl.ly/image/0H40001q3T1Q/android_sqlite_deadlock.png)

* Create a single SQLiteDatabase object that is shared among all threads
* WriterThread spawned
* t0: WriterThread opens a transaction and inserts some data
* t1: WriterThread spawns ReaderThread
* t2: ReaderThread attempts to read some data
* t3: WriterThread calls .join() on ReaderThread to wait for it to finish
* Deadlock! 

## Digging into the deadlock 

* WriterThread has an open transaction, and therefore is holding on to the one and only connection owned by the single SQLiteDatabase object
* ReaderThread is trying to get a new connection to execute its statement, but cannot because WriterThread is holding the only one available
* WriterThread is waiting for ReaderThread to finish so it can finish it's transaction and release the connection.
* Deadlock!

## Code to reproduce the issue

[ThreadsSingleConnectionDeadlock.java](https://github.com/couchbaselabs/android-sqlite-experiments/blob/master/AndroidSQLiteExperiments/src/main/java/com/couchbaselabs/droidsqliteexprmnts/experiments/ThreadsSingleConnectionDeadlock.java)

## Fix Idea #1 - Don't make WriterThread join ReaderThread

This is the somewhat naive and obvious fix.  

In the case of this particular bug, it looks like the code can be reworked to avoid this problem altogether, and should end up with a cleaner design anyway. 

## (Bad) Fix Idea #2 - Each thread gets its own SQLiteDatabase object (for the same database)

You would think this could solve the problem, and it probably would, but there are some major caveats here.

As explained in [Android Sqlite Locking](http://touchlabblog.tumblr.com/post/24474398246/android-sqlite-locking):

> If you try to write to the database from actual distinct connections at the same time, one will fail.  It will not wait till the first is done and then write.  It will simply not write your change.  Worse, if you don’t call the right version of insert/update on the SQLiteDatabase, you won’t get an exception.  You’ll just get a message in your LogCat, and that will be it.

So to avoid this kind of hellish scenario, it's definitely safer to stick with a [Single SQLite connection](http://touchlabblog.tumblr.com/post/24474750219/single-sqlite-connection)

## Is there really a good fix?

So what if you absolutely needed to have the ability to have WriterThread join ReaderThread, and you wanted to avoid giving each thread it's own SQLiteDatabase object, how could that be accomplished?  

Or is that just a silly scenario and it's better to just not do that?  (it seems fairly easy to do it by accident in any scenarios where threads are waiting on another and both accessing the same database)

Actually, I don't know -- it's an open question.  Comments welcome.


