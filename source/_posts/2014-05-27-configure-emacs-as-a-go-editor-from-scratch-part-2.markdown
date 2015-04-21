---
layout: post
title: "Configure Emacs as a Go Editor From Scratch Part 2"
date: 2014-05-27 12:03
comments: true
categories: emacs golang
---


This is a continuation of [Part 1](http://tleyden.github.io/blog/2014/05/22/configure-emacs-as-a-go-editor-from-scratch/), so if you haven't read that already, you should do so now.

## goimports

The idea of goimports is that every time you save a file, it will automatically update all of your imports, so you don't have to.  This can save a lot of time.  Kudos to [@bradfitz](https://twitter.com/bradfitz) for taking the time to build this nifty tool.

go get goimports with:

```
$ go get golang.org/x/tools/cmd/goimports
```

Continuing on previous .emacs in [Part 1](http://tleyden.github.io/blog/2014/05/22/configure-emacs-as-a-go-editor-from-scratch/), update your .emacs to:


```
(defun my-go-mode-hook ()
  ; Use goimports instead of go-fmt
  (setq gofmt-command "goimports")
  ; Call Gofmt before saving
  (add-hook 'before-save-hook 'gofmt-before-save)
  ; Customize compile command to run go build
  (if (not (string-match "go" compile-command))
      (set (make-local-variable 'compile-command)
           "go build -v && go test -v && go vet"))
  ; Godef jump key binding
  (local-set-key (kbd "M-.") 'godef-jump))
(add-hook 'go-mode-hook 'my-go-mode-hook)
```

**Restart emacs** to force it to reload the configuration

### Testing out goimports

* Open an existing .go file that contains imports
* Remove one or more of the imports
* Save the file

After you save the file, it should re-add the imports.  Yay!  

Basically any time you add or remove code that requires a different set of imports, saving the file will cause it to re-write the file with the correct imports.

## The Go Oracle

The [Go Oracle](https://docs.google.com/document/d/1SLk36YRjjMgKqe490mSRzOPYEDe0Y_WQNRv-EiFYUyw/view) will blow your mind!  It can do things like find all the callers of a given function/method.  It can also show you all the functions that read or write from a given channel.  In short, it rocks.

Here's what you need to do in order to wield this powerful tool from within Emacs.

### Go get oracle

```
go get golang.org/x/tools/cmd/oracle
```

### Move oracle binary so Emacs can find it

```
sudo mv $GOPATH/bin/oracle $GOROOT/bin/
```

### Update .emacs

Add the following to your `.emacs` file, **above** the `(defun my-go-mode-hook ()` line.

```
(load-file "$GOPATH/src/golang.org/x/tools/cmd/oracle/oracle.el")
```

**Restart Emacs** to make these changes take effect.

### Get a test package to play with

This package works with go-oracle (I tested it out while writing this blog post), so you should use it to give Go Oracle a spin:

```
go get github.com/tleyden/checkers-bot-minimax
```

### Set the oracle analysis scope

From within emacs, open `$GOPATH/src/github.com/tleyden/checkers-bot-minimax/thinker.go`

You need to tell Go Oracle the **main** package scope under which you want it to operate:

`M-x go-oracle-set-scope`

it will prompt you with:

`Go oracle scope:`

and you should enter:

`github.com/tleyden/checkers-bot-minimax` and hit Enter.

Nothing will appear to happen, but now Go Oracle is now ready to show it's magic.  (*note* it will **not** autocomplete packages in this dialog, which is mildly annoying.  Make sure to spell them correctly.)

**Important:** When you call `go-oracle-set-scope`, you always need to give it a **main** package.  This is something that will probably frequently trip you up while using Go Oracle.

### Use oracle to find the callers of a method

You should still have the `$GOPATH/src/github.com/tleyden/checkers-bot-minimax/thinker.go` file open within emacs.

Position the cursor on the "T" in the `Think` method (line 13 of thinker.go):

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/Emacs_go_oracle_0)

And then run

```
M-x go-oracle-callers
```

Emacs should open a new buffer on the right hand side with all of the places where the `Think` method is called.  In this case, there is only one place in the code that calls it:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/Emacs_go_oracle)

To go to the call site, position your cursor on the red underscore to the left of "dynamic method call" and hit Enter.  It should take you to line 240 in gamecontroller.go:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/Emacs_go_oracle2)

Note that it actually crossed package boundaries, since the called function (`Think`) was in the `main` package, while the call site was in the `checkersbot` package.

If you got this far, you are up and running with The Go Oracle on Emacs!  

Now you should try it with one of your own packages.

This is just scratching the surface -- to get more information on how to use Go Oracle, see [go oracle: user manual](https://docs.google.com/document/d/1SLk36YRjjMgKqe490mSRzOPYEDe0Y_WQNRv-EiFYUyw/view).
