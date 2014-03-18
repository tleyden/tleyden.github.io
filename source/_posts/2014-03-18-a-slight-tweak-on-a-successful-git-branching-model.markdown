---
layout: post
title: "A slight tweak on A Successful Git Branching Model"
date: 2014-03-18 10:32
comments: true
categories: 
---


A great "best practices" for juggling git branches in a release cycle is [A successful git branching model](http://nvie.com/posts/a-successful-git-branching-model/).  It is also accompanied with a tool called [git flow](https://github.com/nvie/gitflow) that makes it easy to implement in practice.

It does however have one major issue: many people use a different naming scheme.  

Instead of:

* **Master** - the latest "stable" branch
* **Development** - bleeding edge development branch

a slightly more common naming pattern is:

* **Master** - bleeding edge development branch
* **Stable** - the latest "stable" branch

To that end, I've tweaked the original diagram to be.

![diagram](http://tleyden-misc.s3.amazonaws.com/blog_images/proposed_couchbaselite_branchingmodel.png)

## Every branch solves a problem

The natural reaction to most people seeing this diagram is *dude, that's way too many branches, this is way more complicated than it needs to be*.  Actually, I'd argue that it's minimally complex to solve the problems that these branches are designed to solve.  In other words, each type of branch jsutifies it's existence by the problem it's designed to solve.

From the perspective of a library developer (in my case, [Couchbase Lite for Android](https://github.com/couchbase/couchbase-lite-android)), here are the problems each branch is purported to solve.

### Permanent and External Facing Branches

*These branches are permanent, in the sense they have a continuous lifetime.  They are also external, and consumers of the library would typically depend on one or both of these branches*

**Master**

* A home for the latest "feature complete" / reviewed code.
* Anyone internal or external who wants to stay up to date with latest project developments needs this branch.


**Stable**

* A home for the code that corresponds to the latest tagged release.
* This branch would be the basis for post-release bugfixes, eg an external developer who finds a bug in the latest release would send a pull request against this branch.
* Developers depending on this code directly in their app would likely point to this branch on their own stable branch.

### Ephemeral and Internal Only Branches

*These branches are emphemeral in nature, and are thrown away once they are no longer useful.  Developers consuming the library would typically ignore these*

**FeatureX** 

* A place for in progress features to live without de-stabilizing the master branch.  Can be many of these.  

**Hotfix** 

* An in progress fix would go here, where that fix is destined to be merged back into latest stable but not part of a new release that is branched off of master.  
* While this hotfix is in progress, since these commits are not part of a tagged release, they cannot go on stable (yet), otherwise it would be a violation of the stable branch contract that says that stable reflects the latest tagged release.  
* They could go directly on a "local stable" branch, which is only on the developers workstation, but that prevents sharing the branch or running CI unit tests against it, so it's not a good solution.
* NOTE: when hotfix merged, new release tagged simultaneously with a merge to stable, so the stable branch contract stays satisfied.

**Release**

* During QA release process, need a place to QA and apply bugfixes, while isolated from destabilizing changes such as merging feature branches.  
* Release branch allows feature branch merging to happen concurrently on master branch, which is especially crucial if release gets delayed.



