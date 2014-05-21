---
layout: post
title: "What is Couchbase Mobile and why should you care?"
date: 2014-05-21 13:57
comments: true
categories: 
---

Couchbase Mobile just announced it's [1.0 release](http://www.couchbase.com/press-releases/couchbase-mobile-enables-new-breed-network-independent-mobile-applications) today.  

What is Couchbase Mobile?

* Couchbase Lite is an open source iOS/Android NoSQL DB with built-in sync capability.  
* Couchbase Mobile refers to the "full stack" solution, which includes the (also open source) server components that Couchbase Lite uses for sync.

To give a deeper look at what problem Couchbase Mobile is meant to solve, let me tell you the story of how I came to discover Couchbase Lite as a developer.  In my [previous startup](http://techcrunch.com/2012/01/26/signature-launches-to-bring-a-personalized-mobile-shopping-service-to-brick-and-mortar-retailers/), we built a mobile CRM app for sales associates.  

The very first pilot release of the app, the initial architecture was:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/architecture_1.png) 

It was very simple, and the server was almost the Single Point of Truth, except for our JSON caching layer which had a very short expiry time before it would refetch from the server.  The biggest downside to this architecture was that *it only worked well when the device had a fast connection to the internet*.

But there was another problem: getting updates to sync across devices in a timely manner.   When sales associate #1 would update a customer, sales associate #2 wouldn't see the change because:

* How does the app for sales associate #2 know it needs to "re-sync" the data?
* How will the app know that something changed on the backend that should cause it to invalidate that locally cached data?

We realized that the data sync between the devices was going to be a huge issue going forward, and so we decided to change our architecture to something like this:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/architecture_2.png)

So the app would be displaying what's stored in the Core Data datastore, and we'd build a *sync engine* component that would shuttle data bidirectionally between Core Data and the backend server.

That seemed like a fine idea on paper, except that I refused to build it.  I knew it would take way too long to build, and once it was built it probably would entail endless debugging and tuning.

Instead, after some intense debate we embarked on a furious sprint to convert everything over to [Couchbase Lite iOS](https://github.com/couchbase/couchbase-lite-ios).  We ended up with an architecture like this:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/architecture%203.png)

It was similar in spirit to our original plans, except **we didn't have to build any of the hard stuff** -- the storage engine and the sync was already taken care of for us by Couchbase Lite.

(*note*: there were also components that listened for changes to the backend server database and fired off emails and push notifications, but I'm not showing them here)

After the conversion ..

**On the upside**

* Any updates to customer data would quickly sync across all devices.
* Our app still worked even when the device was completely offline.
* Our app was orders of magnituted faster in "barely connected" scenarios, because Couchbase Lite *takes the network out of the critical path*.
* Our data was now "document oriented", and so we could worry less about rolling out schema changes while having several different versions of our app out in the wild.

**On the downside**

* We ran into a few bizarre situations where a client app would *regurgitate* a ton of unwanted data back into the system after we'd thought we'd removed it.  To be fair, that was our fault, but I mention it because Couchbase Lite can throw you some curve balls if you aren't paying attention.
* Certain things were awkward.  For example for our initial login experience, we had to sync the data before the sales associate could login.  We ended up re-working that to have the login go directly against the server, which meant that logging in required the user to be online.
* When things went wrong, they were a bit complicated to debug.  (but because Couchbase Lite is Open Source, we could diagnose and fix bugs ourselves, which was a huge win.)

# So what can Couchbase Lite do for you?

## Sync Engine included, so you don't have to build one

If I had to sum up one quick elevator pitch of Couchbase Lite, it would be:

> If you find that you're building a "sync engine" to sync data from your app to other instances of your app and/or the cloud, then you should probably be building it on top of Couchbase Lite instead of going down that rabbit hole -- since you may never make it back out.

## Your app now works well in offline or occasionally connected scenarios

This is something that users expect your app to handle.  For example, if I'm on the BART going from SF -> Oakland and have no signal, I should still be able to read my tweets, and even send new tweets that will be queued to sync once the device comes back online.

If your app is based on Couchbase Lite, you essentially get these features for free.  

* When you load tweets, it is loaded from the local Couchbase Lite store, without any need to hit the server.  
* When you create a new tweet, you just save it to Couchbase Lite, and let it handle the heavy lifting of getting that pushed up to the server once the device is back online.

## Your data model is now Document Oriented

This is a double edged sword, and to be perfectly honest a Document Oriented approach is not always the ideal data model for every application.  However, for some applications (like CRM), it's a much more natural fit than the relational model.

And you'll never have to worry about getting yourself stuck in Core Data schema migration hell.

# What's the dark side of Couchbase Lite?

## Queries can be faster, but they have certain limitations

With SQL, you can run arbitrary queries, irregardless if there is an index or not.

Couchbase Lite cannot be queried with SQL.  Instead you must define *Views*, which are essentially indexes, and run queries on those views.  Views are extremely fast and efficient, but if you don't have a view, you can't run a query, period.

For people who are used to SQL, defining lower level map/reduce views takes some time to wrap your head around.

## Complex queries can get downright awkward

Views are powerful, but they have their limitations, and if your query is complex enough, you may end up needing to write multiple views and coalescing/sorting the data in memory.

## It's not a black box, but it *is* complicated.

The replication code in Couchbase Lite is complicated.  I know, because I've spent a better part of the last year staring at it.

As an app developer, you are putting your trust that the replication will work as you would expect and that it will be performant and easy on the battery.

**The good news** is that it's 100% open source under the Apache 2 license.  So you can debug into it, send issues and pull requests to our [github repo](https://github.com/couchbase/couchbase-lite-android), and even maintain your own fork if needed.



