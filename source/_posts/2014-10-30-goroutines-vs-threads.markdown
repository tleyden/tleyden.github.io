---
layout: post
title: "Goroutines vs Threads"
date: 2014-10-30 06:28
comments: true
categories: golang
---

Here are some of the advantages of Goroutines over threads:

* You can run more goroutines on a typical system than you can threads.
* Goroutines have growable segmented stacks.
* Goroutines have a faster startup time than threads.
* Goroutines come with built-in primitives to communicate safely between themselves (channels).
* Goroutines allow you to avoid having to resort to mutex locking when sharing data structures.
* Goroutines are multiplexed onto a small number of OS threads, rather than a 1:1 mapping.
* You can write massively concurrent servers withouth having to resort to evented programming.

## You can run more of them

On Java you can run 1000's or tens of 1000's threads.  On Go you can run hundreds of thousands or millions of goroutines.

Java threads map directly to OS threads, and are relatively heavyweight.  Part of the reason they are heavyweight is their rather large fixed stack size.  This caps the number of them you can run in a single VM due to the increasing memory overhead.

Go OTOH has a segmented stack that grows as needed.  They are "Green threads", which means the Go runtime does the scheduling, not the OS.  The runtime multiplexes the goroutines onto real OS threads, the number of which is controlled by `GOMAXPROCS`.  Typically you'll want to set this to the number of cores on your system, to maximize potential parellelism.

## They let you avoid locking hell

One of the biggest drawback of threaded programming is the complexity and brittleness of many codebases that use threads to achieve high concurrency.  There can be latent deadlocks and race conditions, and it can become near impossible to reason about the code.

Go OTOH gives you primitives that allow you to avoid locking completely.  The mantra is *don't communicate by sharing memory, share memory by communicating*.  In other words, if two goroutines need to share data, they can do so safely over a channel.  Go handles all of the synchronization for you, and it's much harder to run into things like deadlocks.  

## No callback spaghetti, either

There are other approaches to achieving high concurrency with a small number of threads.  Python Twisted was one of the early ones that got a lot of attention.  Node.js is currently the most prominent evented frameworks out there.

The problem with these evented frameworks is that the code complexity is also high, and difficult to reason about.  Rather than "straightline" coding, the programmer is forced to chain callbacks, which gets interleaved with error handling.  While refactoring can help tame some of the mental load, it's still an issue.









   
