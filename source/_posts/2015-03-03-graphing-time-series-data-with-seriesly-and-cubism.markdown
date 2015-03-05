---
layout: post
title: "Graphing time series data with Seriesly and Cubism"
date: 2015-03-03 16:53
comments: true
categories: seriesly, cubism
---

This will walk you through the basics of putting data into [seriesly](https://github.com/dustin/seriesly) and visualizing it with [cubism](https://square.github.io/cubism/).

You will end up with this in your browser:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/seriesly-cubism.png)

## Install seriesly

```
go get -u -v -t github.com/dustin/seriesly
```

## Run seriesly

```
seriesly -flushDelay=1s -root=/tmp/seriesly-data
```

and leave it running in the background.

## Create a db

In another shell:

```
curl -X PUT http://localhost:3133/testdb
```

## Write docs to db

This script will write json docs with random values for the purpose of visualization.

Copy the following to `add_seriesly_docs.rb`

```
#!/usr/bin/env ruby

6000.times do |count|
  randomNumber = rand() # random number between 0 and 1
  cmd = "curl -X POST -d '{\"index\":#{randomNumber}}' http://localhost:3133/testdb"
  puts cmd
  system(cmd)
  system("sleep 1")
end
```

and then run it

```
chmod +x add_seriesly_docs.rb && ./add_seriesly_docs.rb
```

and let it continue running in the background.

## Create a webserver

Create a directory:

```
mkdir /tmp/seriesly-http/
cd /tmp/seriesly-http/
```

Create `fileserver.go`:

```
package main
import "net/http"
func main() {
        panic(http.ListenAndServe(":8080", http.FileServer(http.Dir("/tmp/seriesly-http/"))))
}
```

Run webserver:

```
go run fileserver.go
```

## Download seriesly.html file

This is a file I wrote which uses seriesly as a metric data source for cubism.  

It's a quick hack, since I couldn't manage to get [seriesism.js](https://github.com/dustin/seriesly/blob/master/cubism/seriesism.js) working.

```
cd /tmp/seriesly-http/
wget https://gist.githubusercontent.com/tleyden/ec0c9be5786e0c0bd9ba/raw/1c08ea13b8ce46e08a49df19ad44c8e6a0ade896/seriesly.html
```

## Open seriesly.html

In your browser, point to [http://localhost:8080/seriesly.html](http://localhost:8080/seriesly.html)

At this point, you should see the screenshot at the beginning of the blog post.

## References

* [seriesly](https://github.com/dustin/seriesly)
* [seriesly blog post](http://dustin.sallings.org/2012/09/09/seriesly.html)
* [The simplest example of cubism](https://sakamotomsh.wordpress.com/2014/05/12/the-simplest-example-of-cubism-js/)