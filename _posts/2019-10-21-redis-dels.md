---
layout: post
title:  "redis key 패턴으로 삭제하기 - dels"
image: ''
date:   2019-10-21 16:00:00
tags:
- redis
description: ''
categories:
- Database
---

<img src="https://octodex.github.com/images/codercat.jpg" alt="">

레디스는 키를 삭제하기 위한 dels를 따로 지원하지 않는다.

그렇기에 keys 패턴을 이용하여 삭제가 가능하다.

{% highlight bash %}
# 0번 db선택
$ redis-cli -n 0 KEYS "your key" | xargs --delim='\n' redis-cli -n 0 DEL
{% endhighlight %}

레디스가 설치된 서버에서 위와 같이 실행하면 원하는 패턴에 해당되는 키들을 삭제할 수 있다.