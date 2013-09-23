---
layout: post
title: "Java coding challenge"
date: 2013-09-19 13:42
comments: true
categories: 
---


Write a server that uses tcp sockets which returns images to clients, and avoids duplicate work for concurrent requests for the same image.

# Description

A server will listen for tcp client connections and generate PNG checkerboard images and return them to clients that request them.  Example checkerboard image:

{% img /images/checkerboard.png 295 105 'image' 'images' %}

The client will send a single parameter to the server after it opens the tcp socket connection to the server:

   * The size of the "checkboard image", which will be a single scalar value like 5, which will result in a 5x5 square, as shown above.

The server will use the following default values when generating the checkerboard image:

   * size: each square will be 60 x 60 pixels.
   * color: squares will be alternating black and white, with black for the square in the 0th row and 0th column, and white for the square in the 1st row and 0th column, etc.  Exactly as shown above.

# Basic Requirements

*  Written in either Java or Scala
*  To generate the actual image, you can use anything you want.  The image format can be any popular image format (PNG, JPEG, GIF, etc..)
*  For the data structures required by the server, you can use any existing data structures within Java itself or a 3rd party, there is no requirement to develop your own.
*  The server will respond with the image data in PNG format, and then close the connection.

# Advanced Requirements

*  In the method that generates the square, there must be a call to Thread.sleep(Y) before returning.  Y represents number of milliseconds to sleep, and will be a random number between 0 and 5000.
*  The server can handle multiple client requests in parallel (as opposed to handling them in serial).  In other words, if client1 contacts the server, and then client2 contacts the server a few milliseconds later, there is a chance that client2 will receive a response before client1, depending on the random sleep described above.
*  In order to avoid needlessly generating the same image twice, if the server is asked to generate a square of size X by client1, and then again asked to generate another square of size X by client2 before it has returned the square to client1, it will simply wait for the square for client1 is finished being generated and return that same square data to both client2 and client1.  Here is an example timeline to show how events would roughly be ordered: 
    * At 12:00:00 Client1 asks for square of size 6
    * At 12:00:01 The server starts to generate the square for client1
    * At 12:00:01 Client2 asks for square of size 6 (the server does *not* try to generate a new square, since there is already a pending request for an identical square)
    * At 12:00:06 The server finishes generating the square of size 6, as originally requested by client1
    * At 12:00:07 The server returns the square to client1
    * At 12:00:07 The server returns the same square to client2

# Deliverables

* server.sh - starts the server that listens on 8000
* client.sh X - runs a client that:
    * connects to localhost:8000
    * passes the parameter X (the size of the checkboard image) to the server
    * reads the PNG into a file called X.png
    * prints a message to say its finished.
* A zip file that contains all jar file dependencies *or* a document that describes on how to download the required dependencies

# Shortcuts

If this feels like too much work, take the following shortcut:

* Rather than return an image, just create a string which would represent the image, where X represents black and O represents white.  Eg, if it was a 2x2 square, return "X00X"

# Bonus points

* Record your commits in a local git repository as you work, and submit a zip file of the repository along with the other deliverables