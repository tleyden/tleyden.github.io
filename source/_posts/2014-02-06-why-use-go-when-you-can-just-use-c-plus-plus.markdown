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

Go, OTOH, has a concept of goroutines and channels for concurrency.  The idea has its roots in CSP (communicating sequential processing), and is not unlike Erlang's style of having processes that communicating by message passing.  So in Go, instead of having threads communicating by sharing memory (and locking), goroutines share memory by communicating over channels.  Eg, concurrent goroutines communicate over channels, and each goroutine's internal state is private to that goroutine.  Also, concurrency and their constructs like channels are built right into the Go language, which affords many advantages over languages that have had concurrency slapped on as an afterthought.

# Go is safer

Go has pointers, but no pointer arithmetic.  

# Go does not have IFDEF's

No IFDEF hell and unmaintainable code.

# Go compiles faster.

Much, much faster.

# Gofmt

All code is uniformly formatted, making codebases much easier to read.  (a la Python)

# Go has garbage collection

This is a double edged sword of course, but lifting the burden from programmers to manage their own memory keeps the codebase a lot cleaner and less error prone than it otherwise would be..

