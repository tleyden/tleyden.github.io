---
layout: post
title: "Understanding function closures in Go"
date: 2016-12-20 18:10
comments: true
categories: golang 
---

Function closures are _really powerful_.  

Essentially you can think of them like _stateful functions_, in the sense that they encapsulate state.  The state that they happen to capture (or "close over" -- hence the name "closure") is everything that's in scope when they are defined.

First some very basic higher order functions.

## Higher order functions

Functions that take other functions and call them are called higher order functions.  Here's a trivial example:

```
func sendLoop(sender func()) {
	sender()
}

func main() {

	mySender := func() {
		fmt.Printf("I should send something\n")
	}
	sendLoop(mySender)

}
```

In the `main()` function, we define a function called `mySender` and pass it to the `sendLoop()` function.  `sendLoop()` takes a confusing looking argument called `sender func()` -- the parameter name is `sender`, and the parameter type is `func()`, which is a function that takes no arguments and returns no values.

To make this slightly less confusing, we can define a named `SenderFunc` function type and use that:

```
// A SenderFunc is a function that takes no arguments, returns nothing
// and presumably sends something
type SenderFunc func()

func sendLoop(sender SenderFunc) {
	sender()
}

func main() {

	mySender := func() {
		fmt.Printf("I should send something\n")
	}

	sendLoop(mySender)

}
```

`sendLoop()` has been updated to take `SenderFunc` as an argument, which is easier to read than taking a `func()` as an argument (which looks a bit like a function call!)  If the `SenderFunc` type took more parameters and/or returned more values, having this in a defined type would be crucial for readability.


## Adding a return value 

Let's make it slightly more realistic -- let's say that the `sendLoop()` might need to retry calling the `SenderFunc` passed to it a few times until it actually works.  So the `SenderFunc` definition will need to be updated so that it returns a boolean that indicates whether a retry is necessary.

```
// A SenderFunc is a function that takes no arguments and returns a boolean
// that indicates whether or not the send needs to be retried (in the case of failure)
type SenderFunc func() bool

func sendLoop(sender SenderFunc) {
	for {
		retry := sender()
		if !retry {
			return
		}
		time.Sleep(time.Second)
	}
}

func main() {

	mySender := func() bool {
		fmt.Printf("I should send something and return a real retry value\n")
		return false
	}

	sendLoop(mySender)

}
```

One thing to note here is the clean separation of concerns -- all `sendLoop()` knows is that it gets a `SenderFunc` which it should call and it will return a boolean indicator of whether or not it worked or not.  It knows absolutely nothing about the inner workings of the `SenderFunc`, nor does it care.

## A stateful sender -- the wrong way

You have a new requirement that you need to only retry the `SenderFunc` 10 times, and then you should give up.

Your first inclination might be to take this approach:

```
// A SenderFunc is a function that takes no arguments and returns a boolean
// that indicates whether or not the send needs to be retried (in the case of failure)
type SenderFunc func() bool

func sendLoop(sender SenderFunc) {
	counter := 0
	for {
		retry := sender()
		if !retry {
			return
		}
		counter += 1
		if counter >= 10 {
			return
		}
		time.Sleep(time.Second)
	}
}

func main() {

	mySender := func() bool {
		fmt.Printf("I should send something and return a real retry value\n")
		return false
	}

	sendLoop(mySender)

}

```

This will work, but it makes the `sendLoop()` less generally useful.  What happens when your co-worker hears about this nifty `sendLoop()` you wrote, and wants to use it with their own `SenderFunc` but wants it to retry 100 times?  (side note: your `SenderFunc` implementation simply prints to the console, whereas theirs might write to a Slack channel, yet the `sendLoop()` will still work!)

To make it more generic, you could take this approach:

```
func sendLoop(sender SenderFunc, maxNumAttempts int) {
	counter := 0
	for {
		retry := sender()
		if !retry {
			return
		}
		counter += 1
		if counter >= maxNumAttempts {
			return
		}
		time.Sleep(time.Second)
	}
}

func main() {

	mySender := func() bool {
		fmt.Printf("I should send something and return a real retry value\n")
		return false
	}

	sendLoop(mySender, 10)

}

```

Which will work -- but there's a catch.  Now that you've changed the method function signature of `sendLoop()` to take a second argument, all of the code that consumes `sendLoop()` will now be broken.  If this were an exported function, it would be an even worse problem.

Luckily there is a much better way.

## A stateful sender -- the right way using function closures

Rather than making `sendLoop()` do the retry-related accounting and passing it parameters for that accounting, you can make the `SenderFunc` handle this and encapsulate the state via a function closure.  In this case, the state is the number of retries that have been attempted, which will start at 0 and then increase on every call to the `SenderFunc`

How can `SenderFunc` keep internal state?  It can "close over" any values that are in scope, which become associated with the function instance (I'm calling it an "instance" because it has state, as we shall see) and will be bound to the function instance as long as the function instance is around.

Here's what the final code looks like:

```

// A SenderFunc is a function that takes no arguments and returns a boolean
// that indicates whether or not the send needs to be retried (in the case of failure)
type SenderFunc func() bool

func sendLoop(sender SenderFunc) {
	for {
		retry := sender()
		if !retry {
			return
		}
		time.Sleep(time.Second)
	}
}

func main() {

	counter := 0              // internal state closed over and mutated by mySender function
	maxNumAttempts := 10      // internal state closed over and read by mySender function

	mySender := func() bool {
		sentSuccessfully := rand.Intn(5)
		if sentSuccessfully {
			return false // it worked, we're done!
		}

		// didn't work, any retries left?
		// only retry if we haven't exhausted attempts
		counter += 1
		return counter < maxNumAttempts

	}

	sendLoop(mySender)

}

```

The `counter` state variable is _bound_ to the `mySender` function instance, which is able to update `counter` on every failed send attempt since the function "closes over" the `counter` variable that is in scope when the function instance is created.  This is the heart of the idea of a function closure.

The `sendLoop()` doesn't know anything about the internals of the `SenderFunc` in terms of how it tracks whether or not it should retry or not, it just treats it as a black box.  Different `SenderFunc` implementations could use vastly different rules and/or states for deciding whether the `sendLoop()` should retry a failed send.

If you wanted to make it even more flexible, you could update the `SenderFunc` to return a `time.Duration` in addition to a `bool` to indicate retry, which would allow you to implement "backoff retry" strategies and so forth.

## What about thread/goroutine safety?

If you're passing the same function instances that have internal state (aka function closures) to multiple goroutines that are calling it, you're going to end up causing data races.  There's nothing special about function closures that protect you from this.

The simplest way to deal with is to make a new function instance for each goroutine you are sending the function instance to, which is probably what you want.  In theory though, you could also wrap the state update in a mutex, which is probably _not_ what you want since that will cause goroutines to block eachother trying to grab the mutex.


