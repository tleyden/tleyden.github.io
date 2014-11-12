---
layout: post
title: "An example of using NSQ from Go"
date: 2014-11-12 07:26
comments: true
categories: golang
---

[NSQ](https://github.com/bitly/nsq) is a message queue, similar to RabbitMQ.  I decided I'd give it a whirl.

## Install Nsq

```
$ wget https://s3.amazonaws.com/bitly-downloads/nsq/nsq-0.2.31.darwin-amd64.go1.3.1.tar.gz
$ tar xvfz nsq-0.2.31.darwin-amd64.go1.3.1.tar.gz
$ sudo mv nsq-0.2.31.darwin-amd64.go1.3.1/bin/* /usr/local/bin
```

## Launch Nsq

```
$ nsqlookupd & 
$ nsqd --lookupd-tcp-address=127.0.0.1:4160 &
$ nsqadmin --lookupd-http-address=127.0.0.1:4161 &
```

## Get Go client library

```
$ go get -u -v github.com/bitly/go-nsq
```

## Create a producer

Add the following code to main.go:

```
package main

import (
	"log"
	"github.com/bitly/go-nsq"
)

func main() {
	config := nsq.NewConfig()
	w, _ := nsq.NewProducer("127.0.0.1:4150", config)

	err := w.Publish("write_test", []byte("test"))
	if err != nil {
		log.Panic("Could not connect")
	}

	w.Stop()
}

```

and then run it with:

```
$ go run main.go
```

If you go to your NSQAdmin at [http://localhost:4171](http://localhost:4171/), you should see a single message in the `write_test` topic.

![NSQAdmin](http://tleyden-misc.s3.amazonaws.com/blog_images/nsq_admin.png)

## Create a consumer

```
package main

import (
	"log"
	"sync"

	"github.com/bitly/go-nsq"
)

func main() {

	wg := &sync.WaitGroup{}
	wg.Add(1)

	config := nsq.NewConfig()
	q, _ := nsq.NewConsumer("write_test", "ch", config)
	q.AddHandler(nsq.HandlerFunc(func(message *nsq.Message) error {
		log.Printf("Got a message: %v", message)
		wg.Done()
		return nil
	}))
	err := q.ConnectToNSQD("127.0.0.1:4150")
	if err != nil {
		log.Panic("Could not connect")
	}
	wg.Wait()

}

```

and then run it with:

```
$ go run main.go
```

You should see output:

```
2014/11/12 08:37:29 INF    1 [write_test/ch] (127.0.0.1:4150) connecting to nsqd
2014/11/12 08:37:29 Got a message: &{[48 55 54 52 48 57 51 56 50 100 50 56 101 48 48 55] [116 101 115 116] 1415810020571836511 2 0xc208042118 0 0}
```



