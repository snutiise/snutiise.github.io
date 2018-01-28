---
layout: post
title:  "Firebase Cloud Function을 이용한 Git Page 기능 구현"
image: ''
date:   2018-01-28 12:00:00
tags:
- firebase
- git
- blog
description: ''
categories:
- Git
---

<img src="https://octodex.github.com/images/codercat.jpg" alt="">

깃 블로그 내에 방문자 카운트 같은 기능을 구현하고 싶어졌다. 

하지만 깃 페이지는 static site이기 때문에 서버단의 구현을 기능하려면 개인 서버나 클라우드를 이용해야한다.

개인서버에 nodejs서버를 구축하여 따로 git blog와의 통신 기능을 구현할까 고민인 도중 firebase를 알게되었다.

## Firebase란?

<img src="https://firebase.google.com/_static/images/firebase/touchicon-180.png">

>Firebase는 실시간 데이터베이스와 백엔드를 서비스로 제공합니다. 이 서비스는 애플리케이션 개발자에게 애플리케이션 데이터를 클라이언트간에 동기화하고 Firebase의 클라우드에 저장할 수있는 API를 제공합니다.

무료사용자의 경우 용량 제한과 트래픽, 성능 제한이 있지만 개인 용도로 사용하기에는 충분하다. 자세한 제한 내용은 <a href="https://firebase.google.com/pricing/?hl=ko">이곳</a>을 클릭!

시작에 앞서 <a href="https://firebase.google.com/?hl=ko">https://firebase.google.com/?hl=ko</a> 접속하여 가입한 뒤 프로젝트를 생성하자.

프로젝트를 생성하여 DEVELOP를 둘러보면 인증, 데이터베이스, 스토리지, 호스팅, 클라우드펑션이 있다.

나는 이중에서 데이터베이스와 백엔드 기능 중 하나인 클라우드 펑션을 사용했다.

## Cloud Function

>Firebase용 Cloud 함수를 사용하면 Firebase 기능 및 HTTPS 요청에 의해 트리거된 이벤트에 대한 응답으로 백엔드 코드를 자동으로 실행할 수 있습니다. 코드는 Google의 클라우드 서비스에 저장되고 관리형 환경에서 실행됩니다. 따라서 직접 서버를 관리하고 크기를 조절할 필요가 없습니다.

정리하면 함수를 작성해서 export하여 deploy하면 "cloud server url + export한 함수 이름"으로 접근시 함수를 실행할 수 있다.

즉, 간단히 api서버를 만들수 있는 것이다.

{% highlight bash %}
#Firebase 설치
$ sudo npm install -g firebase-tools

#Cloud Function 초기화
$ mkdir ~/firebase
$ cd firebase
$ firebase init functions
{% endhighlight %}

firebase를 설치하고 firebase 디렉터리를 클라우드 펑션용으로 초기화 했다.

firebase를 최초 실행시 로그인을 진행해야한다. 가입 아이디와 비밀번호로 로그인하면 초기화를 진행할 수 있다.

처음에는 project 디렉터리를 묻는데 미리 생성해놓은 프로젝트로 설정해주자.

다음으론 cloud function에서 javascript와 typescript중 어느것을 사용할지 묻는데 나는 자바스크립트로 사용했다.

다음은 ESLint를 사용할지 묻는데 따로 설정하기 귀찮아서 no를 선택.

마지막으로 종속성 설치를 묻는데 yes를 눌러주자.

이제 cloud function을 사용할 준비가 전부 끝났다.

초기화가 완료된 디렉터리 내부를 보면 functions라는 디렉터리가 보일텐데 이 디렉터리 안에 있는 index.js가 클라우드 펑션을 작성할 곳이다.

{% highlight javascript %}
//index.js
const functions = require('firebase-functions');
//데이터베이스 사용
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

exports.함수명 = functions.https.onRequest((req, res) => {
    //데이터 조회
    admin.database().ref(경로).once('value').then(function(snapshot) {
    });
    //데이터 입력 set or push
    admin.database().ref(경로).set({data:1});
});
{% endhighlight %}

위와 같이 export.functionName 단위로 코드를 작성해 deploy를 하면 코드가 서버에 올라가서 url접속시 함수를 실행할 수 있다.

req와 res객체는 nodejs express의 req, res와 같아서 입력을 받고싶으면 req로 입력받고 데이터를 반환할때는 res.send()를 이용하면 된다.

이외에 다른 기능들은 <a href="https://firebase.google.com/docs/database/web/read-and-write?authuser=0">가이드</a>나 api 문서를 확인하자.

함수를 구현하고 deploy하는 방법은 아래와 같다.

{% highlight bash %}
#모든 함수 deploy
firebase deploy --only functions

#functionName 함수만 deploy
firebase deploy --only functions:functionName
{% endhighlight %}

성공적으로 deploy를 하고나면 함수를 실행 할 수 있는 url이 콘솔에 보일 것이다.

보통은 "https://us-central1-프로젝트명.cloudfunctions.net/함수명"을 따른다.

이제 해당 url로 git page내에서 ajax 요청을 하면 구현한 기능대로 데이터를 받아올 수 있다.

나는 cloud function을 이용해서 블로그 내 총 방문자와 메뉴 버튼 클릭시 사용자 ip및 방문횟수를 받아오는 api를 구현하여 보여주도록 했다.

귀찮아서 중복 방지 로직 구현안한건 함정...