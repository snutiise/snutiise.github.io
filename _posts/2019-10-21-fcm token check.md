---
layout: post
title:  "fcm token 유효성 검사"
image: ''
date:   2019-10-21 17:00:00
tags:
- android
- fcm
description: ''
categories:
- Programming
---

<img src="https://octodex.github.com/images/codercat.jpg" alt="">

클라이언트에서 받은 fcm token이 유효한지 알려면 아래와 같이 헤더를 설정해서 응답값을 확인하면 된다.

{% highlight bash %}
# FCM_API_KEY와 FCM_TOKEN 설정
$ curl -H "Content-Type: application/json" -H "Authorization: key=$FCM_API_KEY" https://fcm.googleapis.com/fcm/send -d '{"registration_ids":["$FCM_TOKEN"]}'
{% endhighlight %}

{% highlight bash %}
# 성공했을경우 응답
{"multicast_id":1007984435159395389,"success":1,"failure":0,"canonical_ids":0,"results":[{"message_id":"0:1571645063718949%12f57db2f9fd7ecd"}]}
{% endhighlight %}

{% highlight bash %}
# 실패했을경우 응답
{"multicast_id":4920904892700104086,"success":0,"failure":1,"canonical_ids":0,"results":[{"error":"InvalidRegistration"}]}
{% endhighlight %}

성공했을경우 success는 1, 실패하면 0으로 응답이 온다. failure는 그 반대로...

results필드에 어떤 이유로 인증이 실패했는지도 오는것 같다.
