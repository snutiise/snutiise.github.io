---
layout: post
title:  "VS CODE에서 SSH로 Github 연동하기"
image: ''
date:   2018-01-31 03:00:00
tags:
- git
- vs code
description: ''
categories:
- Git
---

<img src="https://octodex.github.com/images/codercat.jpg" alt="">

vs code에서 ssh를 연동하지 않고 github로 push를 하니 매번 아이디와 패스워드를 입력하는것이 귀찮아 졌다...

그래서 ssh를 생성하여 github에 등록하고 remote 주소를 바꿔 편하게 인증하고자 한다!

우선 ssh key를 생성하자

{% highlight bash %}
# 키를 이미 만들어 놨는지 확인...
$ cd ~/.ssh

# 없다면 생성!
$ ssh-keygen  -C "your github email"
{% endhighlight %}

passphrase를 생략하고 만들었기에 엔터 연타...
(물론 취약할 수 있다...!)

다 만들어졌다면 .ssh안에 id_rsa, id_rsa.pub 2개가 생성되었을 것이다.
공개키(id_rsa.pub)는 github에 등록해주면 되고 개인키(id_rsa)는 소중히 간직하자..ㅋㅋ

github에 로그인한 뒤 settings에서 SSH and GPG keys를 클릭한 뒤 New SSH key 클릭!

타이틀은 알아서 생성해주고 key 부분에 공개키(id_rsa.pub)를 넣어주자

저장한 뒤 로컬에서 ssh tset를 해보자

{% highlight bash %}
#ssh agent 구동 여부 확인
$ eval "$(ssh-agent -s)"

#agent에 비밀키 등록
$ ssh-add ~/.ssh/id_rsa

#github ssh 연결 테스트
$ ssh -T git@github.com
{% endhighlight %}

최초 시도시 아마 아래와 같은 문구가 나올것이다.

{% highlight bash %}
The authenticity of host 'github.com (IP ADDRESS)' can't be established.
RSA key fingerprint is SHA256:nThbg6kXUpJWGl7E1IGOCspRomTxdCARLviKw6E5SY8.
Are you sure you want to continue connecting (yes/no)?
{% endhighlight %}

yes를 눌러 다시 한 번 테스트해보면 성공!

그런 다음 자신의 프로젝트에 git remote를 바꿔주자

{% highlight bash %}
#remote 주소 확인
$ git remote -v

#remote 주소 변경
$ git remote set-url origin your_ssh_url
{% endhighlight %}

ssh 연결 주소의 경우 자신의 프로젝트의 clone할때 use ssh 버튼을 눌러보면 주소가 보인다.

{% highlight bash %}
#변경된 remote 주소 확인
$ git remote -v
{% endhighlight %}

이후 변경된 주소를 확인해보면 된다.

https로 push할때마다 id/pw 인증을 해야해서 귀찮았는데 ssh로 바꾸고 나니 편하다.

passphrase를 생략한 경우 보안에 취약하므로 주의해서 비밀키를 관리하자..!
