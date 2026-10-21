---
layout: post
title: "Validating an FCM Token"
date:   2019-10-21 17:00:00
categories:
- Programming
tags:
- android
- fcm
ko_sha: 4c761451038e1760c1b32cfbdbec44b25da0455f
---

There are two ways to validate an FCM token: using the SDK, or querying directly as shown below.

For the SDK approach, refer to <a href="https://firebase.google.com/docs/admin/setup/?hl=ko">here</a>.

This time, let's validate the FCM token by querying directly.

To find out whether an FCM token received from the client is valid, set the headers as below and check the response.

{% highlight bash %}
# Set FCM_API_KEY and FCM_TOKEN
$ curl -H "Content-Type: application/json" -H "Authorization: key=$FCM_API_KEY" https://fcm.googleapis.com/fcm/send -d '{"registration_ids":["$FCM_TOKEN"]}'
{% endhighlight %}

If it succeeds, the response has success as 1 and failure as 0,

{% highlight bash %}
# Response on success
$ {"multicast_id":1007984435159395389,"success":1,"failure":0,"canonical_ids":0,"results":[{"message_id":"0:1571645063718949%12f57db2f9fd7ecd"}]}
{% endhighlight %}

and if it fails, the response has success as 0 and failure as 1.

{% highlight bash %}
# Response on failure
$ {"multicast_id":4920904892700104086,"success":0,"failure":1,"canonical_ids":0,"results":[{"error":"InvalidRegistration"}]}
{% endhighlight %}

Also, on failure, the results field includes the reason for the failure.
