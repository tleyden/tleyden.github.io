---
layout: post
title: "What happens under the hood when you open a web page?"
date: 2016-09-30 20:25
comments: true
categories: internet http tcp html dns
---

First, the bird's eye view:

```
                                                                            
┌────┐                   ┌────────────────┐               ┌────────────────┐
│You │                   │ Google Chrome  │               │    Internet    │
└────┘                   └────────────────┘               └────────────────┘
     │                               │                                  │   
     │    Show me the website for    │                                  │   
     │───organic-juice-for-dogs.io──▶│       1. Hey what's the IP of    │   
     │                               │─────organic-juice-for-dogs.io?──▶│   
     │                               │                                  │   
     │                               │                                  │   
     │                               │◀───────────63.120.10.5───────────│   
     │                               │                                  │   
     │                               │                                  │   
     │                               │        2. HTTP GET / to          │   
     │                               │───────────63.120.10.5───────────▶│   
     │                               │                                  │   
     │                               │                                  │   
     │                               │     HTML Content for homepage    │   
     │                               │◀───────────────of ───────────────│   
     │                               │     organic-juice-for-dogs.io    │   
     │                               │                                  │   
     │                               │                                  │   
     │         3. Render HTML into   │                                  │   
     │◀────────────a Web Page────────│                                  │   
     │                               │                                  │   
     │                               │                                  │   
     │      Click stuff in Google    │                                  │   
     │─────────────Chrome───────────▶│                                  │   
     │                               │                                  │   
     │                               │                                  │   
     │         4. Execute JavaScript │                                  │   
     │◀─────────and update Web Page──┤                                  │   
     │                               │                                  │   
     ▼                               ▼                                  ▼
```


It all starts with a DNS lookup.

## Step 1. The DNS Lookup

Your Google Chrome software contacts a server on the Internet called a DNS server and asks it "Hey what's the IP of organic-juice-for-dogs.io?".

DNS has an official sounding acronym, and for good reason, because it's a very authoritative and fundamental Internet service.

So what exactly is DNS useful for?

**It transforms Domain names into IP addresses**

```
                                                                                   
 ┌────────────────────┐                                     ┌────────────────────┐
 │                    │      What's the IP address of       │                    │
 │                    │─────organic-juice-for-dogs.io?──────▶                    │
 │                    │                                     │                    │
 │       Chrome       │                                     │      DNS Server    │
 │       Browser      ◀───────────63.120.10.5───────────────│                    │
 │                    │                                     │                    │
 │                    │                                     │                    │
 │                    │                                     │                    │
 └────────────────────┘                                     └────────────────────┘
 
```

A **Domain name**, also referred to as a "Dot com name", is an easy-to-remember word or group of words, so people don't have to memorize a list of meaningless numbers.  You could think of it like dialing **1-800-FLOWERS**, which is a lot easier to remember than **1-800-901-1111**

The IP address `63.120.10.5` is just like a phone number.  If you are a human being and want to call someone, you might dial `415-555-1212`.  But if you're a thing on the internet and you want to talk to another thing on the internet, you instead dial the **IP address** `63.120.10.5` -- same concept though.

So, that's DNS in a nutshell.  Not very complicated on the surface.

## Step 2. Contact the IP address and fetch the HTML over HTTP

In this step, Google Chrome sends an `HTTP GET /` HTTP request the HTTP Server software running on a computer somewhere on the Internet that has the IP address `63.120.10.5`.

You can think of the `GET /` as "Get me the top-most web page from the website".  This is known as the *root* of the website, in contrast to things deeper into the website, like `GET /juices/oakland`, which might return a list of dog juice products local to Oakland, CA.  Since the *root* is a the top, that means the tree is actually upside down, and folks tend to think of websites as being structured as *inverted trees*.

The back-and-forth is going to look something like this:


```

 ┌────────────────────┐                                         ┌────────────────────┐
 │                    │          What's the HTML for            │                    │
 │                    ├──────────http://63.120.10.5/?───────────▶                    │
 │                    │                                         │                    │
 │       Chrome       │                                         │    HTTP Server     │
 │       Browser      ◀──────────────<html>stuff</html>─────────│                    │
 │                    │                                         │                    │
 │    HTTP CLIENT     │                                         │                    │
 │                    │                                         │                    │
 └────────────────────┘                                         └────────────────────┘
 
```


These things are speaking **HTTP** to each other.  What is HTTP?

You can think of things that communicate with each other over the internet as using **tubes**.  There are lots of different types of tubes, and in this case it's an HTTP tube.  As long as the software on both ends agree on the type of tube they're using, everything *just works* and they can send stuff back and forth.  HTTP is a really common type of tube, but it's not the only one -- for example the DNS lookup in the previous step used a completely *different* type of tube.

Usually the stuff sent back from the HTTP Server is something called **HTML**, which stands for  **H**yper**T**ext **M**arkup **L**anguage.

But HTML is not the only kind of stuff that can be sent through an HTTP tube.  In fact, JSON (Javascript Object Notation) and XML (eXtensible Markup Language) are also very common.  In fact there are tons of different types of things that can be sent through HTTP tubes.

So at this point in our walk through, the Google Chrome web browser software has some HTML text, and it needs to *render* it in order for it to appear on your screen in a nice easy to view format.  That's the next step.

## Step 3. Render HTML in a Web page

HTML is technically a *markup language*, which means that the text contains *formatting directives* which has an agreed upon standard on how it should be formatted.  You can think of HTML as being similar to a Microsoft Word document, but MS Word is obfuscated while HTML is very transparent and simple:

For example, here is some HTML:

```
<html>
   <Header>My first web page, circa, 1993!</Header>
   <Paragraph>
        I am so proud to have made my very first web page, I <blink>Love</blink> the World Wide Web
   <Paragraph>
   <Footer>Best Viewed on NCSA Mosaic</Footer>
</html>
```

Which gets rendered into:

![image](http://tleyden-misc.s3.amazonaws.com/blog_images/my_first_webpage.jpg)

So, you'll notice that the `<Header>` element is in a larger font.  And the `<Paragraph>` has spaces in between it and the other text.

How does the Google Chrome Web Browser do the rendering?  It's just a piece of software, and rendering HTML is one of it's primary responsibilities.  There are tons of poor engineers at Google who do nothing all day but fix bugs in the Google Chrome rendering code.  

 Of course, there's a lot more to it, but that's the essence of rendering HTML into a web page.  

## Step 4: Execute JavaScript in your Google Chrome Web Browser

So this step is *optional* because not all web pages will execute JavaScript in your web browser software, however it's getting more and more common these days.  When you open the Gmail website in your browser, it's running tons of Javascript code to make the website as fast and responsive as possible.

Essentially, JavaScript adds another level of dynamic abilities to HTML, because when the browser is given HTML and it renders it .. that's it!  There's no more action, it just sits there -- it's completely *inert*.

JavaScript, on the other hand, is basically a program-within-a-program.

```
                                                                  
 ┌───────────────────────────────────────────────────────────────┐
 │                         Google Chrome                         │
 │           (A program written in C++ you downloaded)           │
 │                                                               │
 │                                                               │
 │      ┌──────────────────────────────────────────────────┐     │
 │      │                                                  │     │
 │      │                                                  │     │
 │      │     JavaScript for organic-juice-for-dogs.io     │     │
 │      │  (A program in JavaScript that snuck in via the  │     │
 │      │                  HTML document)                  │     │
 │      │                                                  │     │
 │      │                                                  │     │
 │      └──────────────────────────────────────────────────┘     │
 │                                                               │
 │                                                               │
 └───────────────────────────────────────────────────────────────┘
```

How does the JavaScript get to the web browser?  It sneaks in over the HTML!  It's *embedded* in the HTML, since it's just another form of text, and your Web Browser (Google Chrome) executes it.


```
<html>
     <Javascript>
          if (Paragraph == CLICKED) {
              Window.Alert("YOU MAY BE INFECTED BY A VIRUS, CLICK HERE IMMEDIATELY")
	  }
     </Javascript>
    ...
</html>
```

What can JavaScript do exactly?  The list is really, really long.  But as a simple example, if you click a button on a webpage:

![html button](http://tleyden-misc.s3.amazonaws.com/blog_images/html_button.gif)

A JavasScript program can pop up a little "Alert Box", like this:

![javascript alert](http://tleyden-misc.s3.amazonaws.com/blog_images/javascript_alert.png) 


## Done!

And that's the World Wide Web!  You just went from typing a URL in your browser, from a shiny web page in your Google Chrome.  Soup to nuts.

And you can finally buy some juice for your dog! 

![dogecoin dog](http://tleyden-misc.s3.amazonaws.com/blog_images/doge_coin_hungry_dog.png)

So that's it for the high level stuff.

If you're dying to know more, continue on to [Deep Dive of What Happens Under The Hood When You Open A Web Page](/blog/2016/10/02/deep-dive-of-what-happens-under-the-hood-when-you-open-a-web-page/)

