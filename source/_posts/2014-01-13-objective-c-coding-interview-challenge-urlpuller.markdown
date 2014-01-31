---
layout: post
title: "Objective C coding interview challenge: URLPuller"
date: 2014-01-13 11:45
comments: true
categories: objectivec
---


# Programming Challenge 

The goal is to create a UrlPuller Objective-C class which takes an array of NSURL's that point to PNG images and downloads them asynchronously and writes the contents of each URL to a file.

It should do some basic error handling, which is described below.

The UrlPuller class should have the following instance methods:

- `- (bool) downloadUrlsAsync: (NSArray*)urls`
- `- (void) waitUntilAllDownloadsFinish`
- `- (NSString*) downloadedPathForURL: (NSURL*)url`

Here are the detailed descriptions of each method:

## `- (bool) downloadUrlsAsync: (NSArray*)urls`

The urls array will contain an array of NSURL's, each of which points to a PNG image on the web.  

As long as there is not a download in progress, this will kick off the URLPuller to asynchronously download the PNG image data from each of the given URLs and save the PNG data to a file.  This method should true in this case, and return immediately.

If there is still a download in progress from a previous call to downloadUrlsAsync, then this method will return false immediately and do nothing. 

The downloaded files can be stored in any directory, where the filename is {sha1 hash of url}.png

Downloads should happen concurrently, however it should also be "nice" and not completely exhaust system resources if it is called with a list of 10K URL's.

Retry behavior: if any of the downloads fail in a way that could be transient, it should wait 10 seconds and retry that URL. The delay doubles after each failure.  After 3 attempts, it gives up on that URL.

## `- (void) waitUntilAllDownloadsFinish` 

Block until all of the URLs have been downloaded.

If this is called while there is no download in progress, it should return immediately.  Otherwise, it should block until all the downloads have finished or fail after 3 attempts.

## `- (NSString*) downloadedPathForURL: (NSURL*)url`

If this is called but downloadUrlsAsync was never previously called on this instance, it should return nil.

If a download is in progress, it should wait until all downloads have finished (by calling waitUntilAllDownloadsFinish), and then return the downloaded path for the given url.

If a download is not in progress, but one has completed previously, it should return the downloaded path for the given url in the last previously completed download.

# Expectations/Requirements 

* Write a program that satisfies the API methods and described behavior.  
* The code should be easy to read and understand.
* An instance of the URLPuller class would only be accessed by a single thread.
* You are not required to write any unit tests.
* URL downloads should happen concurrently, but it should be "nice" in terms of not exhausting system resources.

# Rules 

* You can use any available resource you can find on the Internet -- eg, Stack Overflow, API docs, etc.
* You may not ask questions related to the problem on Stack Overflow, IRC, etc.  (eg, the Internet is "read-only")
* You cannot use any 3rd party libraries or products, you can only use classes and API's in the standard iOS/Cocoa Objective-C runtime
* It should be possible to run this project via XCode (it can be an OSX command line app, or an iOS app, whatever is convenient)
