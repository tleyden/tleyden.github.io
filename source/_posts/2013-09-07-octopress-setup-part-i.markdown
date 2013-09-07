---
layout: post
title: "Octopress Setup Part I"
date: 2013-09-07 11:26
comments: true
categories: [octopress, blog]
---

I'm writing this blog entry as I'm creating my blog.  I have decided to use [Octopress](http://octopress.org/), and I'm initially going to host it on [Github Pages](http://pages.github.com/).

## Step 1: create a github pages repo

In my case, I made a new repo called tleyden/tleyden.github.io.

## Step 2: push an index.html 

Clone the repo

```
$ git clone git@github.com:tleyden/tleyden.github.io.git
```

Add some content

```
$ cd tleyden.github.io
$ echo "<h1>hello</h1>" > index.html
```

Commit and push

```
$ git add index.html
$ git commit -m "empty blog"
$ git push origin master
```

## Step 3: see if it actually worked

Go to http://tleyden.github.io/ to see if it works.

**It did not work.  WTH!?**

Oh wait, it says: *It may take up to ten minutes until your page is available.*

Patiently hit reload 5 times / minute, and 7 minutes later .. **IT WORKS!**


## Step 4: get rvm (octopress dependency)

```
$ \curl -L https://get.rvm.io | bash
$ source /Users/traun/.rvm/scripts/rvm
$ rvm notes
```

## Step 5: get ruby 1.9.3 (octopress dependency)

``` 
$ rvm install 1.9.3
Searching for binary rubies, this might take some time.
No binary rubies available for: osx/10.8/x86_64/ruby-1.9.3-p448.
Continuing with compilation. Please read 'rvm help mount' to get more information on binary rubies.
Checking requirements for osx.
Installing requirements for osx.
Updating system......
Error running 'requirements_osx_brew_update_system ruby-1.9.3-p448',
please read /Users/traun/.rvm/log/1378534467_ruby-1.9.3-p448/update_system.log
Requirements installation failed with status: 1.
```

I managed to get past this error by following this [stack overflow post](http://stackoverflow.com/questions/14113427/brew-update-failed)

Let's try this again ..

```
Installing required packages: gcc46, libyaml, libksba, openssl......................................................................................................
```

45 minutes later, it finally worked.  
```
$ rvm use 1.9.3
$ rvm rubygems latest
```

## Step 6: get octopress

Follow the [Setup Ocotpress](http://octopress.org/docs/setup/) instructions

## Step 7: recreate repo

So this is a little _awkward_, and looking back I wish I hadn't pushed that index.html earlier, because it interferes with the github push in the next step.

* Delete your entire github repository: `username/username.github.io`
* Create a new empty github repository: `username/username.github.io`

## Step 8: deploy to github pages

Follow the [Deploy to Github pages](http://octopress.org/docs/deploying/github/) instructions.

There is one step that is crucial if you don't want to accidentally lose your blog content:

```
git add .
git commit -m 'your message'
git push origin source
```

After doing that, your github repo should have two branches:

* Master: the "published blog" goes here, and will have a top-level index.html
* Source: the entire octopress source tree, plus a "source" and "sass" directory.  The "source" directory is where your blog markdown content will actually live.

## Step 9: write a blog entry 

Follow the [New blog post](http://octopress.org/docs/blogging/) instructions.

## Step 10: re-deploy 

From the last step in the [Deploy to Github pages](http://octopress.org/docs/deploying/github/) instructions, do the following:

```
$ rake generate
$ rake deploy
```

## Step 11: revel in it's beauty

![screenshot](http://cl.ly/image/1e2x3I293X3w/Screen%20Shot%202013-09-07%20at%2012.21.57%20AM.png)



