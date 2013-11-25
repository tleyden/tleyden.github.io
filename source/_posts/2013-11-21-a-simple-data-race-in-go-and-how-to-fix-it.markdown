---
layout: post
title: "A simple data race in Go and how to fix it"
date: 2013-11-21 08:16
comments: true
categories: [golang]
---

Suppose you want to add an http handler which can show some things that in memory.  

Simple, right?  Actually, if you aren't careful, doing this can lead to data races, even though only one goroutine is writing the data at any given time.

Here's the golang code (also on [github](https://github.com/tleyden/go-scratchpad/blob/1521d96e8f093b06ed57cd32e702b8ccb458e270/concurrentaccess/main.go)) that reproduces the issue:

```
type Foo struct {
	content string
}

type FooSlice []*Foo

func updateFooSlice(fooSlice FooSlice) {
	for {
		foo := &Foo{content: "new"}
		(*fooSlice)[0] = foo
		time.Sleep(time.Second)
	}
}

func installHttpHandler(fooSlice FooSlice) {
	handler := func(w http.ResponseWriter, r *http.Request) {
		for _, foo := range fooSlice {
			if foo != nil {
				fmt.Fprintf(w, "foo: %v ", (*foo).content)
			}
		}

	}
	http.HandleFunc("/", handler)
}

func main() {
	foo1 := &Foo{content: "hey"}
	foo2 := &Foo{content: "yo"}
	fooSlice := FooSlice{foo1, foo2}

	installHttpHandler(fooSlice)

	go updateFooSlice(fooSlice)

	http.ListenAndServe(":8080", nil)
}

```


if you run this code with `go run main.go` and then open `http://localhost:8080` in your browser, it will work as expected.  

But not so fast!  Lurking in this code are data races, and if you run this with race detection enabled using `go run -race main.go` and then access it with the browser, it will panic with:

```
==================
WARNING: DATA RACE
Read by goroutine 6:
  main.func·001()
      /../concurrentaccess/main.go:45 +0x9e
      ...
Previous write by goroutine 4:
  main.updateFooSlice()
      /../concurrentaccess/main.go:35 +0x98
      ...
```

because there are two goroutines accessing the same slice without any protection -- the main goroutine running the http server, and the goroutine running `updateFooSlice`.

## Fix #1 - use sync.mutex to lock the slice

This isn't necessarily the _best_ way to fix this, but it's the simplest to understand and explain.  

Here are the changes to the code (also on [github](https://github.com/tleyden/go-scratchpad/blob/8f031806d5f0d7becef844f5400f2cc663ff4bf7/concurrentaccess/main.go)):

* Import the `sync` package
* Create a sync.Mutex object in the package-global namespace
* Before updating the slice, lock the mutex, and after updating it, unlock it.
* Before the http handler access the slice, it locks the mutex, and after it's done, it unlocks it.

```
type Foo struct {
	content string
}

type FooSlice []*Foo

var mutex sync.Mutex

func updateFooSlice(fooSlice FooSlice) {
	for {
		mutex.Lock()
		foo := &Foo{content: "new"}
		fooSlice[0] = foo
		fooSlice[1] = nil
		mutex.Unlock()
		time.Sleep(time.Second)
	}
}

func installHttpHandler(fooSlice FooSlice) {
	handler := func(w http.ResponseWriter, r *http.Request) {
		mutex.Lock()
		defer mutex.Unlock()
		for _, foo := range fooSlice {
			if foo != nil {
				fmt.Fprintf(w, "foo: %v ", (*foo).content)
			}
		}
	}
	http.HandleFunc("/", handler)
}

func main() {

	foo1 := &Foo{content: "hey"}
	foo2 := &Foo{content: "yo"}

	fooSlice := FooSlice{foo1, foo2}

	installHttpHandler(fooSlice)

	go updateFooSlice(fooSlice)

	http.ListenAndServe(":8080", nil)

}

```

If you now re-run the code with the `-race` flag and access `http://localhost:8080`, it won't panic.  

## Digression - chan chan

Before we can talk about Fix #2, we need to take a digression to talk about chan chan's -- channels which contain other channels as the morsels of data that pass through the channel tubes (metachannels, if you will).

**tl;dr** A channel describes a transport of sorts.  You can send a thing down that transport.  When using a chan chan, the thing you want to send down the transport is another transport to send things back.

If it's still a little fuzzy for you, here's the [long description of chan chan's with diagrams](http://tleyden.github.io/blog/2013/11/23/understanding-chan-chans-in-go/)

## Fix #2 - Use channels instead of `sync.Mutex`


In this version of the fix, the goroutine running the http handler (the main goroutine in this case), makes a response chan and passes it into a request chan chan that both goroutines can access.  It then reads the response from the response chan, which will contain a copy of the FooSlice.

```
func installHttpHandler(fooSlice FooSlice) {
        handler := func(w http.ResponseWriter, r *http.Request) {
                response := make(chan FooSlice)
                request <- response
                fooSliceCopy := <-response
                for _, foo := range fooSliceCopy {
                        if foo != nil {
                                fmt.Fprintf(w, "foo: %v ", (*foo).content)
                        }
                }
        }
        http.HandleFunc("/", handler)
}
```

The other goroutine updates the FooSlice and is also checking the request chan chan for new messages.  If it gets a new request message, it makes a copy of the FooSlice and sends it to the response chan.

```
func updateFooSlice(fooSlice FooSlice) {
        t := time.Tick(time.Second)
        for {
                select {
                case <-t:
                        foo := &Foo{content: "new"}
                        fooSlice[0] = foo
                        fooSlice[1] = nil
                case ch := <-request:
                        fooSliceCopy := make(FooSlice, len(fooSlice))
                        copy(fooSliceCopy, fooSlice)
                        ch <- fooSliceCopy
                }
        }
}
```

Again, if you now re-run this code with the `-race` flag and access `http://localhost:8080`, it won't panic.  

The full code sample is [available on gihub](https://github.com/tleyden/go-scratchpad/blob/e92685b35c2d6f61274c7e72a3cdebf85817878a/concurrentaccess/main.go)
