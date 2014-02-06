---
layout: post
title: "Why use Go when you can just use C++?"
date: 2014-02-06 08:25
comments: true
categories: 
---

I recently saw this on a mailing list:

> What are the advantages of Go against C++ or other languages?


# Go has sane concurrency.

In C++ the main tool to deal with concurrency is pthreads, but making threaded programming correct is extremely difficult and error prone.  Trying to make it performant by minimizing locking makes it even more challenging.

Go, OTOH, has a concept of goroutines and channels for concurrency.  The idea has its roots in CSP (communicating sequential processing), and is not unlike Erlang's style of having processes that communicating by message passing.  

In Go, instead of having threads communicating by sharing memory (and locking), goroutines share memory by communicating over channels.  Eg, concurrent goroutines communicate over channels, and each goroutine's internal state is private to that goroutine.  Also, concurrency and their constructs like channels are built right into the Go language, which affords many advantages over languages that have had concurrency slapped on as an afterthought.

# Other Strengths

* No unsafe pointer arithmetic.  
* Array bound checking
* Write once run anywhere
* Closures (eg, lambdas)
* Functions are first class objects
* Multiple return values
* Does not have IFDEF's, so o IFDEF hell and unmaintainable code.
* Compiles blazingly fast
* Gofmt - All code is uniformly formatted, making codebases much easier to read.  (a la Python)
* Garbage collection


# Weaknesses

* Lack of generics
* Not quite as fast as C/C++ (partly due to GC overhead)
* Integration with existing native code is a bit limited (you can't build libraries in Go or link Go code into a C/C++ executable)
* IDE support is limited compared to C/C++/Obj-C/Java
* Doesn't work with regular debugging tools because it doesn't use normal calling conventions.
