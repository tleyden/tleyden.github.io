---
layout: post
title: "Configure Emacs as a Go editor from scratch"
date: 2014-05-22 16:46
comments: true
categories: emacs golang
---

This explains the steps to get a productive Emacs environment for Go programming on OSX, starting from scratch.  

## Install Emacs 

I recommend using the emacs from [emacsformacosx.com](http://emacsformacosx.com).  

It has a GUI installer so I won't say much more about it.

## Install lastest version of Go

See [Installing Go](https://golang.org/doc/install)

After installing, you'll want to define the following environment variables in your `~/.bash_profile`. 

```
export GOROOT=/usr/local/go            
export GOPATH=~/Development/gocode
export PATH=$PATH:$GOROOT/bin
export PATH=$PATH:$GOPATH/bin
```

These might be different on your system.

## Install additional go tools (godoc, etc)

To get the `godoc` tool as well as others, run:

```
go get golang.org/x/tools/cmd/...
```

I ended up getting an error:

```
$ go get golang.org/x/tools/cmd/...
# golang.org/x/tools/go/ssa/interp
Development/gocode/src/golang.org/x/tools/go/ssa/interp/external.go:244: undefined: syscall.Pipe2
```

which is documented in [issue 13831](https://github.com/golang/go/issues/13831)

And installing these tools directly via:

```
go get golang.org/x/tools/cmd/godoc
go get golang.org/x/tools/cmd/cover
go get golang.org/x/tools/cmd/gorename
go get golang.org/x/tools/cmd/goimports
go get golang.org/x/tools/cmd/oracle
go get golang.org/x/tools/cmd/vet
```

## Install Melpa

[Melpa](http://melpa.org/#/getting-started) is a package manager for Emacs, and is required for [go-mode](https://github.com/dominikh/go-mode.el)

To configure emacs for melpa:

* Create a new file `~/.emacs.d/init.el`
* Add the following contents:

```
(require 'package)
(add-to-list 'package-archives
  '("melpa" . "http://melpa.milkbox.net/packages/") t)
```

Restart emacs and run `M-x package-list-packages` and you should see it contacting `http://melpa.milkbox.net` and you should also see lot of packages listed as being from the melpa archive.

## Install go-mode

Run `M-x package-install` and when prompted, enter `go-mode` and hit enter.

I got the following warnings:

```
Compiling file /Users/tleyden/.emacs.d/elpa/go-mode-20160127.4/go-mode.el at Sat Feb  6 17:58:11 2016
Entering directory `/Users/tleyden/.emacs.d/elpa/go-mode-20160127.4/'
go-mode.el:16:1:Warning: cl package required at runtime

In go-mode:
go-mode.el:917:10:Warning: `font-lock-syntactic-keywords' is an obsolete
    variable (as of 24.1); use `syntax-propertize-function' instead.

```

Restart Emacs and open a .go file, you should see the mode as "Go" rather than "Fundamental".

For a full description of what go-mode can do for you, see [Dominik Honnef's blog](http://dominik.honnef.co/posts/2013/03/writing_go_in_emacs/), but one really useful thing to be aware of is that you can quickly import packages via `C-c C-a`

## Update Emacs path to find `godoc`

Run `M-x package-install` and enter `exec-path-from-shell`

I got this warning:

```
Compiling file /Users/tleyden/.emacs.d/elpa/exec-path-from-shell-20160112.2246/exec-path-from-shell-pkg.el at Sat Feb  6 18:20:55 2016
Entering directory `/Users/tleyden/.emacs.d/elpa/exec-path-from-shell-20160112.2246/'

Compiling file /Users/tleyden/.emacs.d/elpa/exec-path-from-shell-20160112.2246/exec-path-from-shell.el at Sat Feb  6 18:20:55 2016

In exec-path-from-shell-setenv:
exec-path-from-shell.el:189:11:Warning: assignment to free variable
    `eshell-path-env'
```

Restart emacs.

## Update Emacs config for `godoc`

It's really useful to be able to able to pull up 3rd party or standard library docs from within Emacs using the `godoc` tool.

**PATH**

Add the following to your `~/.emacs.d/init.el` file so that it gets the PATH environment:

```
(defun set-exec-path-from-shell-PATH ()
  (let ((path-from-shell (replace-regexp-in-string
                          "[ \t\n]*$"
                          ""
                          (shell-command-to-string "$SHELL --login -i -c 'echo $PATH'"))))
    (setenv "PATH" path-from-shell)
    (setq eshell-path-env path-from-shell) ; for eshell users
    (setq exec-path (split-string path-from-shell path-separator))))

(when window-system (set-exec-path-from-shell-PATH))
```

NOTE: according to [this StackOverflow post](http://stackoverflow.com/questions/6411121/how-to-make-emacs-use-my-bashrc-file), it's possible to achieve this via downloading the [exec-path-from-shell](https://github.com/purcell/exec-path-from-shell) emacs plugin from Marmelade or Melpa.

**GOPATH**

```
(setenv "GOPATH" "/Users/tleyden/Development/gocode")
```

(replace the above path to the absolute path to the directory where you store your Go code)

After doing this step, you should be able to run `M-x godoc` and it should be able to autocomplete paths of packages.  (of course, you may want to `go get` some packages first if you don't have any)

## Automatically call gofmt on save

`gofmt` reformats code into the One True Go Style Coding Standard.  You'll want to call it every time you save a file.

Add these to your `~/.emacs.d/init.el`:

```
(setq exec-path (cons "/usr/local/go/bin" exec-path))
(add-to-list 'exec-path "/Users/tleyden/Development/gocode/bin")
(add-hook 'before-save-hook 'gofmt-before-save)
```

(replace the above path to the absolute path to your `$GOPATH/bin` directory)

After this step, whenever you save a Go file, it will automatically reformat the file with `gofmt`.

## Godef 

Godef is essential: it lets you quickly jump around the code, as you might be used to with a full featured IDE.

From what I can tell, installing [go-mode](https://github.com/dominikh/go-mode.el) seems to automatically install godef.  

To verify that godef is indeed installed:

* Putting the cursor over a method name 
* Try doing `M-x godef-jump` to jump into the method, and `M-*` to go back.

In order to add godef key bindings, add these to your `~/.emacs.d/init.el`:

```
(defun my-go-mode-hook ()
  ; Call Gofmt before saving                                                    
  (add-hook 'before-save-hook 'gofmt-before-save)
  ; Godef jump key binding                                                      
  (local-set-key (kbd "M-.") 'godef-jump))
(add-hook 'go-mode-hook 'my-go-mode-hook)
```

and remove your previous call to `(add-hook 'before-save-hook 'gofmt-before-save)` since it's now redundant

Now you can jump into code with `M-.` and jump back with `M-*`

## Autocomplete

Install melpa auto-complete via `M-x package-install` followed by `auto-complete`

I got [these warnings](:https://gist.github.com/tleyden/cecfbba9bd9112fb71ae)

Add the following to your `~/.emacs.d/init.el` file:

```
(defun auto-complete-for-go ()
  (auto-complete-mode 1))
(add-hook 'go-mode-hook 'auto-complete-for-go)
```

Restart emacs, and if you open a .go file the mode should be `Go AC` (AC == AutoComplete)

Before further verifying, we need to install gocode in the next step.

## Gocode: Go aware Autocomplete

**This step seems broken (see details below), if you have any ideas on how to make it work, leave a comment**

The following is a brief summary of the [gocode README](https://github.com/nsf/gocode)

* `go get -u -v github.com/nsf/gocode`
* `cp /Users/tleyden/Development/gocode/src/github.com/nsf/gocode/emacs/go-autocomplete.el ~/.emacs.d/`
* Add the following to your `~/.emacs.d/init.el`

```
(require 'go-autocomplete)
(require 'auto-complete-config)
(ac-config-default)
```

At this point, after you restart emacs, when you start typing something, you should see a popup menu with choices, like [this screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/emacs_autocomplete.png).

On my system I'm getting this error:

```
Warning (initialization): An error occurred while loading `/Users/tleyden/.emacs.d/init.el':

File error: Cannot open load file, no such file or directory, go-autocomplete
```

## Customize compile command to run `go build`

It's convenient to be able to run `M-x compile` to compile and test your Go code from within emacs.  

To do that, edit your `~/.emacs.d/init.el` and replace your go-mode hook with:

```
(defun my-go-mode-hook ()
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

After that, restart emacs, and when you type `M-x compile`, it should try to execute `go build -v && go test -v && go vet` instead of the default behavior.  On some projects, you might also want to run `go generate` before `go build`

**Power tip**: you can jump straight to each compile error by running ``C-x ` ``.  Each time you do it, it will jump to the next error.


## Continue to Part 2

go-imports and go-oracle are covered in [Part 2](../../27/configure-emacs-as-a-go-editor-from-scratch-part-2/)

## References

* [5 minutes of go in emacs](http://www.youtube.com/watch?v=5wipWZKvNSo) by [@dlsspy](https://twitter.com/dlsspy)




