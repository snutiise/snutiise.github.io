---
layout: post
title: "Deleting Redis Keys by Pattern - dels"
date:   2019-10-21 16:00:00
categories:
- Database
tags:
- redis
ko_sha: bd7796d3594972b6894f8060cd8ca5d68f65c2f0
---

Redis does not provide a separate dels command for deleting keys.

Instead, you can delete them using a keys pattern.

{% highlight bash %}
# Select DB 0
$ redis-cli -n 0 KEYS "your key" | xargs --delim='\n' redis-cli -n 0 DEL
{% endhighlight %}

Run the command above on the server where Redis is installed, and you can delete the keys that match the pattern you want.