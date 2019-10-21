---
layout: post
title:  "Electron 데스크탑 알림"
image: ''
date:   2018-02-26 06:00:00
tags:
- electron
- javascript
- html5
description: ''
categories:
- Programming
---

<img src="https://octodex.github.com/images/codercat.jpg" alt="">

지난번 채팅앱을 구현할 때 child window를 통해서 알림창을 구현했다.

그때에는 언급하지 못했지만 electron의 경우 notification을 제공한다. 

main process에서 notification 모듈을 통해 알림창 표시가 가능하지만 os 제약이 심한편이다. (windows계열이 문제이다.)

결국은 main process에서 알림창을 범용적으로 구현하고 싶으면 child window로 직접 구현하는게 속편하다.

renderer process 경우는 html5 notification api를 이용하면 보편적으로 알림창을 제공할 수 있다.

아래 간단한 예제 코드를 통해 테스트 할 수 있다. 

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

renderer process에서 html5 api를 사용하면 알림창을 보다 쉽게 구현할 수 있다.

html5 notification api에 대해서는 <a href="https://developer.mozilla.org/ko/docs/Web/API/notification">API 문서</a>를 눌러 확인해보자
