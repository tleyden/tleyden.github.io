---
layout: post
title: "A successful git branching model with enterprise support"
date: 2014-04-09 11:39
comments: true
categories: 
---

This further extends [A Slight Tweak on a Successful Git Branching Model](http://tleyden.github.io/blog/2014/03/18/a-slight-tweak-on-a-successful-git-branching-model/) with the addition of the concept of support branches.

![diagram](http://tleyden-misc.s3.amazonaws.com/blog_images/release-branching-strategy.png)

## Release Branches

* When completed the release branch would be merged into both the master and stable branches, the commit on the stable branch would be tagged with a release tag (eg, 1.0.0).

* The release branch would be discarded after being merged back into master and stable.

* Release branches would be named “release/xxx”, where xxx is the target release tag for that release.  Eg, “release/1.0.0”.

* Release branches should only have bugfixes related to the release being committed to them.  All other changes should be on feature branches or the master branch, isolated from the release process.

* Release branches would help avoid making developers having to “double-commit” bugfixes related to a release to both the release branch and the master branch -- because the release branch will be merged into master at the time of release, they only need to commit the fix to the release branch.

* Release branches should be periodically merged back into the master branch if they run longer than normal (eg, if it was expected to last 3 weeks and ended up lasting 8 weeks), rather than waiting until the time of release.  This will reduce the chance of having major merge conflicts trying to merge back into master.

* When a release is ready to be tagged, if the release branch does not easily merge into master, it is up to the dev lead on that team to handle the merge (not the build engineer).  In this case, the build engineer should not be blocked, because the merge into stable will be a fast-forward merge, and so the release can proceed despite not having been merged into master yet.

## Support Branches

* Support branches would be created “on demand” when requested by customers who are stuck on legacy releases and are not able to move forward to current releases, but need security and other bug fixes.  

* Support branches should be avoided if possible, by encouraging customers to move to the current release, because they create extra work for the entire team.

* Support branches would follow a similar naming scheme and would be named “support/xxx”, where xxx is the release tag from which they were branched off of.  Eg, “support/1.0.1”.

* Support branches are essentially dead-end branches, since their changes would unlikely need to be merged back into master (or stable) as the support branch contains “ancient code” and most likely those fixes would already have been integrated into the codebase.  

* If a customer is on the current release, then there is no need to create a support branch for their required fix.  Instead, a hotfix branch should be used and a new release tag should be created.

## Hotfix Branches

* Hotfix branches would branch off of the stable branch, and be used for minor post-release bugfixes.  

* Hotfix branches would be named “hotfix/xxx”, where xxx might typically be an issue id.  Once their changes have been merged into master and stable, they should be deleted.

* Hotfix branches are expected to undergo less QA compared to release branches, and therefore are expected to contain minimum changes to fix showstopper bugs in a release.   The changes should not include refactoring or any other risky changes.

* If it’s being branched off the master branch, it’s not a hotfix branch.  Hotfixes are only branched off the stable branch.

*  Hotfix branches should verified on the CI server using the automated QA suite before being considered complete.

* After being accepted by QA, hotfix branches are merged back into master and stable, and the latest commit on stable is tagged with a release tag.  (eg, 1.0.1)

* Similar to release branches, if hotfixes do not easily merge back into master, the build engineer would assign the dev lead the responsibility for completing the merge, but this should not block the release.  However since hotfix branches are so short-lived, this is very unlikely to happen.

## Stable Branch

* The stable branch would represent the “released” mainline development.  

* The latest commit on stable should always correspond to the latest release tag.  

* All release tags should be made against commits on stable, except for those on legacy support branches. 

* Developers who wanted to subscribe to the latest released code would follow the stable branch.

## Master Branch

* The master branch would represent the “as-yet-unreleased” mainline development.  

## Feature Branches

* All non-trivial changes should be done on feature branches and undergo code review before being merged into the master branch.