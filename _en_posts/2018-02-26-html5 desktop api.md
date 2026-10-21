---
layout: post
title: "Electron Desktop Notifications"
date:   2018-02-26 06:00:00
categories:
- Programming
tags:
- electron
- javascript
- html5
ko_sha: 82a89b2c48ee43fcf6c28c8b979d3e9da554154a
---

When I built the chat app last time, I implemented the notification window with a child window.

I did not mention it then, but Electron provides notifications.

The main process can show a notification window through the notification module, but OS restrictions are quite severe. (The Windows family is the problem.)

In the end, if you want a general-purpose notification window in the main process, it is less stressful to implement it yourself with a child window.

In the renderer process, you can provide notification windows universally with the HTML5 notification API.

You can test it with the simple example code below.

{% highlight javascript %}
<button onclick="notifyMe()">Notify me!</button>

<script>
function notifyMe() {
  // Let's check if the browser supports notifications
  if (!("Notification" in window)) {
    alert("This browser does not support desktop notification");
  }

  // Let's check whether notification permissions have already been granted
  else if (Notification.permission === "granted") {
    // If it's okay let's create a notification
    var notification = new Notification("Hi there!");
  }

  // Otherwise, we need to ask the user for permission
  else if (Notification.permission !== 'denied') {
    Notification.requestPermission(function (permission) {
      // If the user accepts, let's create a notification
      if (permission === "granted") {
        var notification = new Notification("Hi there!");
      }
    });
  }

  // At last, if the user has denied notifications, and you 
  // want to be respectful there is no need to bother them any more.
}Notification.requestPermission().then(function(result) {
  console.log(result);
});function spawnNotification(theBody,theIcon,theTitle) {
  var options = {
      body: theBody,
      icon: theIcon
  }
  var n = new Notification(theTitle,options);
}
</script>
{% endhighlight %}

Using the HTML5 API in the renderer process makes it easier to implement a notification window.

For the HTML5 notification API, click <a href="https://web.archive.org/web/20171206155122/https://developer.mozilla.org/ko/docs/Web/API/notification">API documentation</a> to check it out.
