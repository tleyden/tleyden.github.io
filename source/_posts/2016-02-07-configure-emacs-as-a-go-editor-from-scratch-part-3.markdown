---
layout: post
title: "Configure Emacs as a Go Editor From Scratch Part 3"
date: 2016-02-07 04:25
comments: true
categories: emacs golang
---

This is a continuation from [a previous blog post](http://tleyden.github.io/blog/2014/05/27/configure-emacs-as-a-go-editor-from-scratch-part-2/).  In this post I'm going to focus on making emacs look a bit better.

Currently:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/emacs_ugly.png) 

## Install a nicer theme

I like the `taming-mr-arneson-theme`, so let's install that one.  Feel free to browse the emacs themes and find one that you like more.

```
$ `mkdir ~/.emacs.d/color-themes`
$ `wget https://raw.githubusercontent.com/emacs-jp/replace-colorthemes/d23b086141019c76ea81881bda00fb385f795048/taming-mr-arneson-theme.el`
```

Update your `~/emacs.d/init.el` to add the following lines to the top of the file:

```
(add-to-list 'custom-theme-load-path "/Users/tleyden/.emacs.d/color-themes/")
(load-theme 'taming-mr-arneson t)
```

Now when you restart emacs it should look like this:

![screenshot](http://tleyden-misc.s3.amazonaws.com/blog_images/emacs_taming_mr_arneson.png)


 ## Directory Tree

```
$ cd ~/DevLibraries
$ git clone https://github.com/jaypei/emacs-neotree.git neotree
```

Update your `~/emacs.d/init.el` to add the following lines:

```
(add-to-list 'load-path "/some/path/neotree")
(require 'neotree)
```

Open a `.go` file and the enter `M-x neotree-dir` to show a directory browser:

![screnshot](http://tleyden-misc.s3.amazonaws.com/blog_images/emacs-neotree.png)

Ref: [NeoTree](http://www.emacswiki.org/emacs/NeoTree)