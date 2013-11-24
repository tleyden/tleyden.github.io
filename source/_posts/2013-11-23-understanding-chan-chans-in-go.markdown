---
layout: post
title: "Understanding chan chan's in Go"
date: 2013-11-23 07:58
comments: true
categories: [golang]
---

A channel describes a transport of sorts.  You can send a thing down that transport.  When using a chan chan, the thing you want to send down the transport is another transport to send things back.

They are useful when you want to get a response to something, and you don't want to setup two channels (it's generally considered bad practice to have data moving bidirectionally on a single channel)

## Visual time lapse walkthrough

Keep in mind that Goroutine C is the "real consumer" even though it will be the one which writes to the request channel.

The request channel starts out empty.

![Screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/go_chan_chan_1.png)

Goroutine C passes a "response channel" to go routine D via the request channel

![Screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/go_chan_chan_2.png)

Goroutine C starts reading from the (still empty) response channel.  


![Screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/go_chan_chan_3.png)

Goroutine D writes a string to the response channel

![Screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/go_chan_chan_4.png)

Goroutine C now is able to read a value from response channel, and get's the "wassup!" message

![Screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/go_chan_chan_5.png)

And now we are back to where we started

![Screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/go_chan_chan_1.png)

## And here is some code

```
package main

import "fmt"
import "time"

func main() {

     // make the request chan chan that both go-routines will be given
     requestChan := make(chan chan string)

     // start the goroutines
     go goroutineC(requestChan)
     go goroutineD(requestChan)

     // sleep for a second to let the goroutines complete
     time.Sleep(time.Second)

}

func goroutineC(requestChan chan chan string) {

     // make a new response chan
     responseChan := make(chan string)

     // send the responseChan to goRoutineD
     requestChan <- responseChan

     // read the response
     response := <-responseChan

     fmt.Printf("Response: %v\n", response)

}

func goroutineD(requestChan chan chan string) {

     // read the responseChan from the requestChan
     responseChan := <-requestChan

     // send a value down the responseChan
     responseChan <- "wassup!"

}

```

This code can be run on [Go playground](http://play.golang.org/p/chi6P2XGTO)