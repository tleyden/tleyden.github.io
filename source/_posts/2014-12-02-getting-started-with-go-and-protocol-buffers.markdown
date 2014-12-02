---
layout: post
title: "Getting started with Go and Protocol Buffers"
date: 2014-12-02 06:32
comments: true
categories: golang
---

I found the [official docs](https://github.com/golang/protobuf) on using Google Protocol Buffers from Go a bit confusing, and couldn't find any other clearly written blog posts on the subject, so I figured I'd write my own.

This will walk you through the following:

* Install golang/protobuf and required dependencies
* Generating Go wrappers for a test protocol buffer definition
* Using those Go wrappers to marshal and unmarshal an object

## Install protoc binary

Since the protocol buffer compiler `protoc` is required later, we must install it.

**Ubuntu 14.04**

If you want to use an older version (v2.5), simply do:

```
$ apt-get install protobuf-compiler
```

Otherwise if you want the latest version (v2.6):

```
$ apt-get install build-essential
$ wget https://protobuf.googlecode.com/svn/rc/protobuf-2.6.0.tar.gz
$ tar xvfz protobuf-2.6.0.tar.gz
$ cd protobuf-2.6.0
$ ./configure && make install
```

**OSX**

```
$ brew install protobuf
```

## Install Go Protobuf library

This assumes you have Go 1.2+ or later already installed, and your `$GOPATH` variable set.

In order to generate Go wrappers, we need to install the following:

```
$ go get -u -v github.com/golang/protobuf/proto
$ go get -u -v github.com/golang/protobuf/protoc-gen-go
```

## Download a test .proto file

In order to generate wrappers, we need a `.proto` file with object definitions.  

This one is a slightly modified version of the one from the [official docs](https://github.com/golang/protobuf).

```
$ wget https://gist.githubusercontent.com/tleyden/95de4bfe34321c79e91b/raw/f8696fe0f1462f377d6bd13c5f20cccfa182578a/test.proto
```

## Generate Go wrappers

```
$ protoc --go_out=. *.proto
```

You should end up with a new file generated: `test.pb.go`


## Marshalling and unmarshalling an object

Open a new file `main.go` in [emacs](http://tleyden.github.io/blog/2014/05/22/configure-emacs-as-a-go-editor-from-scratch/) or your favorite editor, and paste the following:

```
package main

import (
	"log"

	"github.com/golang/protobuf/proto"
)

func main() {

	test := &Test{
		Label: proto.String("hello"),
		Type:  proto.Int32(17),
		Optionalgroup: &Test_OptionalGroup{
			RequiredField: proto.String("good bye"),
		},
	}
	data, err := proto.Marshal(test)
	if err != nil {
		log.Fatal("marshaling error: ", err)
	}
	newTest := &Test{}
	err = proto.Unmarshal(data, newTest)
	if err != nil {
		log.Fatal("unmarshaling error: ", err)
	}
	// Now test and newTest contain the same data.
	if test.GetLabel() != newTest.GetLabel() {
		log.Fatalf("data mismatch %q != %q", test.GetLabel(), newTest.GetLabel())
	}

	log.Printf("Unmarshalled to: %+v", newTest)

}
```

Explanation:

* Lines 11-14: Create a new object suitable for protobuf marshalling and populate it's fields.  *Note that using `proto.String(..)` / `proto.Int32(..)` isn't strictly required, they are just convencience wrappers to get string / int pointers*.
* Line 18: Marshal to a byte array.
* Line 22: Create a new empty object.
* Line 23: Unmarshal previously marshalled byte array into new object
* Line 28: Verify that the "label" field made the marshal/unmarshall round trip safely

**Run it via:**

```
$ go run main.go test.pb.go
```

and you should see the output:

```
Unmarshalled to: label:"hello" type:17 OptionalGroup{RequiredField:"good bye" }	
```

Congratulations!  You are now using protocol buffers from Go.

## References

* [Official golang/protobuf repo](https://github.com/golang/protobuf)
* [gogoprotobuf fork](https://code.google.com/p/gogoprotobuf/)
