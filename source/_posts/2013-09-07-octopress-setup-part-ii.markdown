---
layout: post
title: "Octopress Setup Part II"
date: 2013-09-07 11:46
comments: true
categories: [blog, octopress]
---

# Showing my tweets on my blog

What's a blog without a few tweets to spice it up?

Here's my first attempt, which didn't work.  I modified my _config.yml file to have:

```
twitter_user: tleydn
```

After some desperate googling, I came across [this blog post](http://blog.jmac.org/blog/2013/03/30/putting-twitter-back-into-octopress/) which seems to suggest that twitter support has been remoted from Octopress, with instructions on how to embed a twitter widget.

Here's a few tricks to make it looks slightly less butt-ugly:

* In the twitter widget generator, choose the "dark" theme.
* Modify the widget class to have dimensions `width="300" height="350"` so that it is slightly less distracting when viewing content.

# Adding an "About" page

I followed the instructions on [Theming & Customization](http://octopress.org/docs/theme/template/), which added an About section on the top of the sidebar on the right side.

# Enabling Disqus comments

This was trivial:

* Go to [Disqus](http://disqus.com) and register a new site
* Add the "shortname" to the _config.yml file

# Let's pimp this thing -- Adding an image in the header

* Open octopress/source/_includes/custom/header.html
* Find an image graphic and save it into octopress/source/images (in my case, it was /images/rabbit_hole_graphic.png)
* Add a new html table element, and in one cell add a link to the image with the appropriate size dimensions.

Example header.html file:

{% raw %}
```
  <table><tr><td>
  <h1><a href="{{ root_url }}/">{{ site.title }}</a></h1>
  {% if site.subtitle %}
    <h2>{{ site.subtitle }}</h2>
  {% endif %}
  </td><td>&nbsp;&nbsp;
  {% img left /images/rabbit_hole_graphic.png 295 105 'image' 'images' %}
  </td></tr>
  </table>

```
{% endraw %}

I'm not a hipster, it's just that my HTML coding skillz are stuck at about 1995.  If you are seething with the overwhelming urge to tell me how to do this in 2013 CSS style, go right ahead and add a comment.

Anyway, the end justifies the means:

{% img center /images/ScreenShotBlogIIa.png 'image' 'images' %}
