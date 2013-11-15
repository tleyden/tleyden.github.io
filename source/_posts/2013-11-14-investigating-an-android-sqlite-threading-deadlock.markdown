---
layout: post
title: "Investigating an Android SQLite threading deadlock"
date: 2013-11-14 11:24
comments: true
categories: 
---

In an unreleased version of Couchbase Lite for Android, I was seeing the following error:

```
SQLiteConnectionPool The connection pool for database has been unable to grant a connection to thread
SQLiteConnectionPool(14004): Connections: 0 active, 1 idle, 0 available.
```

## Here's what turned out to be happening

* Create a single SQLiteDatabase object that is shared among all threads
* Thread1 spawned
* Thread2 spawned
* Thread1 opens a transaction and inserts some data
* Thread1 calls .join() on Thread2 to wait for it to finish
* Thread2 attempts to read some data
* Deadlock! 

## Digging into the deadlock 

* Thread1 has an open transaction, and therefore is holding on to the one and only connection owned by the single SQLiteDatabase object
* Thread2 is trying to get a new connection to execute its statement, but cannot because Thread1 is holding the only one available
* Thread1 is waiting for Thread2 to finish so it can finish it's transaction and release the connection.
* Deadlock!

## Code to reproduce the issue

[ThreadsSingleConnectionDeadlock.java](https://github.com/couchbaselabs/android-sqlite-experiments/blob/master/AndroidSQLiteExperiments/src/main/java/com/couchbaselabs/droidsqliteexprmnts/experiments/ThreadsSingleConnectionDeadlock.java)

## Fix Idea #1 - Don't make Thread1 join Thread2

This is the somewhat naive and obvious fix.  

In the case of this particular bug, it looks like the code needs to be reworked anyway, which will make that fix in the process.

## (Bad) Fix Idea #2 - Each thread gets its own SQLiteDatabase object (for the same database)

You would think this could solve the problem, and it probably would, but there are some major caveats here.

As explained in [Android Sqlite Locking](http://touchlabblog.tumblr.com/post/24474398246/android-sqlite-locking):

> If you try to write to the database from actual distinct connections at the same time, one will fail.  It will not wait till the first is done and then write.  It will simply not write your change.  Worse, if you don’t call the right version of insert/update on the SQLiteDatabase, you won’t get an exception.  You’ll just get a message in your LogCat, and that will be it.

So to avoid this kind of hellish scenario, it's definitely safer to stick with a [Single SQLite connection](http://touchlabblog.tumblr.com/post/24474750219/single-sqlite-connection)

## Is there really a good fix?

So what if you absolutely needed to have the ability to have Thread1 join Thread2, and you wanted to avoid giving each thread it's own SQLiteDatabase object, how could that be accomplished?  

Or is that just a silly scenario and it's better to just not do that?  (it seems fairly easy to do it by accident in any scenarios where threads are waiting on another and both accessing the same database)

Actually, I don't know.. it's an open question.  Comments welcome.


