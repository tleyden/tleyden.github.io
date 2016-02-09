---
layout: post
title: "Adding vendoring to a Go project"
date: 2016-02-08 22:49
comments: true
categories: golang
---

## Install gvt

After doing some research, I decided to try `gvt` since it seemed simple and well documented, and integrated well with exiting tools like `go get`.

```
$ export GO15VENDOREXPERIMENT=1
$ go get -u github.com/FiloSottile/gvt
```

## Go get target project to be updated

I'm going to update [todolite-appserver](https://github.com/tleyden/todolite-appserver) to use vendored dependencies for *some* of it's dependencies, just to see how things go.

```
$ go get -u github.com/tleyden/todolite-appserver
```

## Vendor dependencies

I'm choosing the dependency on [kingpin](github.com/alecthomas/kingpin) since it has dependencies of it's own (github.com/alecthomas/units, etc).

```
$ gvt fetch github.com/alecthomas/kingpin
```

Now my directory structure looks like this:

```
├── main.go
└── vendor
    ├── github.com
    │   └── alecthomas
    ├── gopkg.in
    │   └── alecthomas
    └── manifest
```

Here is the [manifest](https://gist.github.com/tleyden/60328c7e0fd778970314)

`gvt list` shows the following:

```
$  gvt list
github.com/alecthomas/kingpin  https://github.com/alecthomas/kingpin  master 46aba6af542541c54c5b7a71a9dfe8f2ab95b93a
github.com/alecthomas/template https://github.com/alecthomas/template master 14fd436dd20c3cc65242a9f396b61bfc8a3926fc
github.com/alecthomas/units    https://github.com/alecthomas/units    master 2efee857e7cfd4f3d0138cc3cbb1b4966962b93a
gopkg.in/alecthomas/kingpin.v2 https://gopkg.in/alecthomas/kingpin.v2 master 24b74030480f0aa98802b51ff4622a7eb09dfddd
```

## Verify it's using the vendor folder


I opened up the `vendor/github.com/alecthomas/kingpin/global.go` and made the following change:

```
// Errorf prints an error message to stderr.
func Errorf(format string, args ...interface{}) {
	fmt.Println("CALLED IT!!")
	CommandLine.Errorf(format, args...)
}
```

Now verify that code is getting compiled and run:

```
$ go run main.go changesfollower
CALLED IT!!
main: error: URL is empty
```

## Restore the dependency

Before I check in the `vendor` directory to git, I want to reset it to it's previous state before I made the above change to the `global.go` source file.

```
$ gvt restore
```

Now if I open `global.go` again, it's back to it's original state.  Nice!

## Add the vendor folder and push

```
$ git add vendor
$ git commit -m "..."
$ git push origin master
```

Also, I updated the README to tell users to set the `GO15VENDOREXPERIMENT=1` variable:


```
$ export GO15VENDOREXPERIMENT=1
$ go get -u github.com/tleyden/todolite-appserver
$ todolite-appserver --help
```

but the instructions otherwise remained the same.  If someone tries to use this but forgets to set `GO15VENDOREXPERIMENT=1` in Go 1.5, it will still work, it will just use the kingpin dependency in the `$GOPATH` rather than the `vendor/` directory.  Ditto for someone using go 1.4 or earlier.

## Removing a vendored dependency

As it turns out, I don't even need kingpin in this project, since I'm using [cobra](https://github.com/spf13/cobra).  The kingpin dependency was caused by some leftover code I forgot to cleanup.

To remove it, I ran:

```
$ gvt delete github.com/alecthomas/kingpin
$ gvt delete github.com/alecthomas/template
$ gvt delete github.com/alecthomas/units
$ gvt delete gopkg.in/alecthomas/kingpin.v2
```

In this case, since it was my only dependency, it was easy to identify the transitive dependencies.  In general though it looks like it's up to you as a user to track down which ones to remove.  I filed [gvt issue 16](https://github.com/FiloSottile/gvt/issues/16) to hopefully address that.

## Editor annoyances

I have emacs setup using the [steps in this blog post](http://tleyden.github.io/blog/2014/05/22/configure-emacs-as-a-go-editor-from-scratch/), and I'm running into the following annoyances:

* When I use `godef` to jump into the code of vendored dependency, it takes me to source code that lives in the `GOPATH`, which might be *different* than what's under `vendor/`.  Also, if I edit it there, my changes won't be reflected when I rebuild.
* I usually search for things in the project via `M-x rgrep`, but now it's searching through every repo under `vendor/` and returning things I'm not interested in .. since most of the time I only want to search within my project.



