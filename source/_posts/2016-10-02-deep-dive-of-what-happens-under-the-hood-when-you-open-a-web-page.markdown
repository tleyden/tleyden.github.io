---
layout: post
title: "Deep Dive of What Happens Under The Hood When You Open A Web Page"
date: 2016-10-02 12:50
comments: true
categories: internet http tcp html dns
---

This is a continuation of [What Happens Under The Hood When You Open A Web Page](/blog/2016/09/30/the-lifecycle-of-an-http-request/), and it's meant to be a deeper dive.

### Clients and Servers

Remember back in the day when you wanted to know what time it was, and you picked up your phone and dialed 853-1212 and it said "At the tone, the time will be 8:53 AM?".

Those days are over, but the idea lives on.  The time *service* is identical in principal to an internet *server*.  You ask it something, and it gives you an answer.

A well designed service does one thing, and one thing well.

* With the time service, you can only ask one kind of question: "What time is it?"

* With a DNS server, you can only ask one kind of question: "What is the IP address of organic-juice-for-dogs.io"

Clients vs Servers:

* A "Client" can essentially be thought of as being a "Customer".  In the case of calling the time, it's the person dialing the phone number.  In the case of DNS, it's the Google Chrome browser asking for the IP address.

* A "Server" can be thought of as being a "Service".  In the case of calling the time, it's something running at the phone company.  In the case of DNS, it's a service run by a combination of universities, business, and governments.

## Web Browsers

The following programs are all web browsers, which are all technically HTTP Clients, meaning they are on the client end of the HTTP tube.

* Google Chrome
* Safari
* Firefox
* Internet Explorer
* Etc..

What web browsers do:

* Lookup IP addresses from DNS servers over the DNS protocol (which in turn sits on top of the UDP protocol) 
* Retrieve web pages, images, and more from web servers over the HTTP protocol (which in turn sits on top of the TCP protocol) 
* Render HTML into formatted "pages"
* Executes JavaScript code to add a level of dynamic behavior to web pages

## Protocols

In the previous post, there were a few "protocols" mentioned, like HTTP.

What are protocols really?

**Any protocol is something to make it possible for things that speak the same protocol to speak to each other over that protocol.**

A protocol is just a *language*, and just like everyone in English-speaking countries agree to speak English and can therefore intercommunicate without issues, many things on the internet agree to speak HTTP to each other.

Here's what a conversation looks like in the HTTP protocol:

```
HTTP Client: GET /
HTTP Server: <html>I'm a <blink>amazing</blink> HTML web page!!</html>
```

Almost everything that happens on the Internet looks something like this:

```
                                                                                      
 ┌────────────────────┐                                         ┌────────────────────┐
 │                    │                                         │                    │
 │                    │                                         │                    │
 │                    │                                         │                    │
 │     Internet       ◀──────────────Protocol───────────────────▶    Internet        │
 │     Thing 1        │                                         │    Thing 2         │
 │                    │                                         │                    │
 │                    │                                         │                    │
 │                    │                                         │                    │
 └────────────────────┘                                         └────────────────────┘
```

There are lots of different protocols, which are just "languages" that things on the Internet use to speak to each other.  You and I speak English.  Many things on the Internet speak protocols like HTTP, others speak different protocols like DNS.

Let's look at a few, at a very high level.

### **TCP** and **UDP** 

You can think of the internet as being made up of *tubes*.  Two very common types of tubes are:

* TCP (Transmission Control Protocol)
* UDP (User Datagram Protocol) 

Here's what an internet tube looks like:

![image](http://tleyden-misc.s3.amazonaws.com/blog_images/internet-tube.jpg)

### **IP**

Really, you can think of TCP and UDP as internet tubes that are built from the same kind of concrete -- and that concrete is called IP (Internet Protocol)

TCP *wraps* IP, in the sense that it is built on top of IP.  If you took a *slice* of a TCP internet tube, it would look like this:

```                                           
 ┌───────────────────────────────────────────┐
 │   TCP - (Transmission Control Protocol)   │
 │                                           │
 │                                           │
 │       ┌──────────────────────────┐        │
 │       │ IP - (Internet Protocol) │        │
 │       │                          │        │
 │       │                          │        │
 │       │                          │        │
 │       └──────────────────────────┘        │
 │                                           │
 └───────────────────────────────────────────┘
```                                              

Ditto for UDP -- it's also built on top of IP.  The slice of a UDP internet tube would look like this:

```                                              
 ┌───────────────────────────────────────────┐
 │    UDP - (Universal Datagram Protocol)    │
 │                                           │
 │                                           │
 │       ┌──────────────────────────┐        │
 │       │ IP - (Internet Protocol) │        │
 │       │                          │        │
 │       │                          │        │
 │       │                          │        │
 │       └──────────────────────────┘        │
 │                                           │
 └───────────────────────────────────────────┘
```

IP, or "Internet Protocol", is fancy way of saying "How machines on the Internet talk to each other", and **IP addresses** are their equivalent of phone numbers.

Why do we need two types of tubes built on top of IP?  They have different properties:

* TCP tubes are heavy weight, they take a long time to build, and a long time to tear down, but they are super reliable.
* UDP tubes are light weight, and have no guarantees. They're like the `¯\_(ツ)_/¯` of internet tubes.  If you send something down a UDP internet tube, you actually have no idea whether it will make it down the tube or not.  It might seem useless, but it's not.  Pretty much all real time gaming, voice, and video transmissions go through UDP tubes.


## HTTP tubes

If you take a slice of an HTTP tube, it looks like this:


```
┌───────────────────────────────────────────────────────────┐
│           HTTP - (HyperText Transfer Protocol)            │
│                                                           │
│       ┌───────────────────────────────────────────┐       │
│       │   TCP - (Transmission Control Protocol)   │       │
│       │                                           │       │
│       │        ┌──────────────────────────┐       │       │
│       │        │ IP - (Internet Protocol) │       │       │
│       │        │                          │       │       │
│       │        └──────────────────────────┘       │       │
│       │                                           │       │
│       └───────────────────────────────────────────┘       │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

Because HTTP *sits on top of* TCP, which in turn *sits on top of* IP.

### DNS tubes

DNS tubes are very similar to HTTP tubes, except they sit on top of UDP tubes.  Here's what a slice might look like:


```
┌───────────────────────────────────────────────────────────┐
│                DNS - (Domain Name Service)                │
│                                                           │
│       ┌───────────────────────────────────────────┐       │
│       │    UDP - (Universal Datagram Protocol)    │       │
│       │                                           │       │
│       │        ┌──────────────────────────┐       │       │
│       │        │ IP - (Internet Protocol) │       │       │
│       │        │                          │       │       │
│       │        └──────────────────────────┘       │       │
│       │                                           │       │
│       └───────────────────────────────────────────┘       │
│                                                           │
└───────────────────────────────────────────────────────────┘
```


## Actually, internet tubes are more complicated

So when your Google Chrome web browser gets a web page over an HTTP tube, it actually looks more like this:

```
                                                 
              ┌────────────────────┐             
              │                    │             
              │       Chrome       │             
              │       Browser      │             
              │                    │             
              └─────────┬────▲─────┘             
                        │    │                   
                        │    │                   
              ┌─────────▼────┴─────┐             
              │                    │             
              │   Some random      │             
              │  computer in WA    │             
              │                    │             
              └─────────┬─────▲────┘             
              ┌─────────▼─────┴────┐             
              │                    │             
              │   Some random      │             
              │  computer in IL    │             
              │                    │             
              └────────┬───▲───────┘             
              ┌────────▼───┴───────┐             
              │                    │             
              │   Some random      │             
              │  computer in MA    │             
              │                    │             
              └──────────┬───▲─────┘             
                         │   │                   
                         │   │                   
                         │   │                   
     Send me the HTML    │   │ <html>stuff</html>
                         │   │                   
                         │   │                   
                         │   │                   
                         │   │                   
              ┌──────────▼───┴─────┐             
              │                    │             
              │    HTTP Server     │             
              │                    │             
              └────────────────────┘
```

Each of these random computers in between are called *routers*, and they basically shuttle traffic across the internet.  They make it possible that any two computers on the internet can communicate with each other, without having a direct connection.

If you're curious to know which computers are in the middle of your connection between you and another computer on the internet, you can run a nifty little utility called `traceroute`:

```
$ traceroute google.com
traceroute to google.com (172.217.5.110), 64 hops max, 52 byte packets
 1  dd-wrt (192.168.11.1)  1.605 ms  1.049 ms  0.953 ms
 2  96.120.90.157 (96.120.90.157)  9.334 ms  8.796 ms  8.850 ms
 3  te-0-7-0-18-sur03.oakland.ca.sfba.comcast.net (68.87.227.209)  9.744 ms  9.416 ms  9.120 ms
 4  162.151.78.93 (162.151.78.93)  12.310 ms  11.559 ms  11.662 ms
 5  be-33651-cr01.sunnyvale.ca.ibone.comcast.net (68.86.90.93)  11.276 ms  11.187 ms  12.426 ms
 6  hu-0-13-0-1-pe02.529bryant.ca.ibone.comcast.net (68.86.84.14)  11.624 ms
    hu-0-12-0-1-pe02.529bryant.ca.ibone.comcast.net (68.86.87.14)  11.637 ms
    hu-0-13-0-0-pe02.529bryant.ca.ibone.comcast.net (68.86.86.94)  12.404 ms
 7  as15169-3-c.529bryant.ca.ibone.comcast.net (23.30.206.102)  11.024 ms  11.498 ms  11.148 ms
 8  108.170.243.1 (108.170.243.1)  11.037 ms
    108.170.242.225 (108.170.242.225)  12.246 ms
    108.170.243.1 (108.170.243.1)  11.482 ms
```

So from my computer to the computer at google.com, it goes through all of those intermediate computers.  Some have DNS names, like `be-33651-cr01.sunnyvale.ca.ibone.comcast.net`, but some only have IP addresses, like `162.151.78.93`

Any one of those computers could *sniff* the traffic going through the tubes (even the **IP** tubes that all the other ones sit on top of!).  That's why you don't want to send your credit cards over the internet without using encryption!

## The End

