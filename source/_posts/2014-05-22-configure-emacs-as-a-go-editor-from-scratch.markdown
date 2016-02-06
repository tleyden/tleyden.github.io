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

## Install Go

* At the time of writing (05/22/2014), I installed https://storage.googleapis.com/golang/go1.2.2.darwin-amd64-osx10.8.pkg
* After installing the package, you'll want to define the following environment variables in your `~/.bash_profile`:

```
export GOROOT=/usr/local/go
export GOPATH=~/Development/gocode
export PATH=$PATH:$GOROOT/bin
```

## Configure go-mode

Go-mode is an Emacs major mode for editing Go code.  An absolute must for anyone writing Go w/ Emacs.

The following is a brief summary of [Dominik Honnef's instructions](http://dominik.honnef.co/posts/2013/03/writing_go_in_emacs/)

* `mkdir -p ~/Misc/emacs && cd ~/Misc/emacs`
* `git clone git@github.com:dominikh/go-mode.el.git`
* From within Emacs, run `M-x update-file-autoloads`, point it at the **go-mode.el** file in the cloned directory.
* Emacs will prompt you for a result path, and you should enter **~/Misc/emacs/go-mode.el/go-mode-load.el** 
* Add these two lines to your ~/.emacs  (if you don't already have this file, you should create an empty one)

```
(add-to-list 'load-path "~/Misc/emacs/go-mode.el/")
(require 'go-mode-load)
```

Restart Emacs and open a .go file, you should see the mode as "Go" rather than "Fundamental".

For a full description of what go-mode can do for you, see [Dominik Honnef's blog](http://dominik.honnef.co/posts/2013/03/writing_go_in_emacs/), but one really useful thing to be aware of is that you can quickly import packages via `C-c C-a`

## Update Emacs config for `godoc`

It's really useful to be able to able to pull up 3rd party or standard library docs from within Emacs using the `godoc` tool.

**PATH**

Add the following to your `.emacs` file so that it gets the PATH environment:

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

Add these to your ~/.emacs:

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

In order to add godef key bindings, add these to your ~/.emacs:

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

The following is a brief summary of the [emacs autocomplete manual](http://cx4a.org/software/auto-complete/manual.html#Installation)

* Download and extract http://cx4a.org/pub/auto-complete/auto-complete-1.3.1.tar.bz2
* Cd into extracted dir and run `emacs -batch -l etc/install.el`
* Create a `lisp` subdirectory under your `~/.emacs.d` directory
* When prompted for where to install, give it the full path to your `~/.emacs.d/lisp` directory, eg: `/Users/tleyden/.emacs.d/lisp`
* It will tell you to add the following to your ~/.emacs:

```
(add-to-list 'load-path "/Users/tleyden/.emacs.d/lisp")
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "/Users/tleyden/.emacs.d/lisp/ac-dict")
(ac-config-default)
```

To see any effect, we need to install gocode in the next step.

## Gocode: Go aware Autocomplete

The following is a brief summary of the [gocode README](https://github.com/nsf/gocode)

* `go get -u -v github.com/nsf/gocode`
* `cp /Users/tleyden/Development/gocode/src/github.com/nsf/gocode/emacs/go-autocomplete.el ~/.emacs.d/`
* Add the following to your ~/.emacs

```
(require 'go-autocomplete)
(require 'auto-complete-config)
```

At this point, after you restart emacs, when you start typing something, you should see a popup menu with choices, like [this screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/emacs_autocomplete.png).

## Customize compile command to run `go build`

It's convenient to be able to run `M-x compile` to compile and test your Go code from within emacs.  

To do that, edit your ~/.emacs and replace your go-mode hook with:

```
(defun my-go-mode-hook ()
  ; Call Gofmt before saving
  (add-hook 'before-save-hook 'gofmt-before-save)
  ; Customize compile command to run go build
  (if (not (string-match "go" compile-command))
      (set (make-local-variable 'compile-command)
           "go generate && go build -v && go test -v && go vet"))
  ; Godef jump key binding
  (local-set-key (kbd "M-.") 'godef-jump))
(add-hook 'go-mode-hook 'my-go-mode-hook)
```

After that, restart emacs, and when you type `M-x compile`, it should try to execute `go build -v && go test -v && go vet` instead of the default behavior.

**Power tip**: you can jump straight to each compile error by running ``C-x ` ``.  Each time you do it, it will jump to the next error.

## Ready for more?

If you're ready to take it to the next level, check out [5 minutes of go in emacs](http://www.youtube.com/watch?v=5wipWZKvNSo)

(PS: thanks [@dlsspy](https://twitter.com/dlsspy) for taking the time to teach me the Emacs wrestling techniques needed to get this far.)

## Continue to Part 2

go-imports and go-oracle are covered in [Part 2](../../27/configure-emacs-as-a-go-editor-from-scratch-part-2/)




