---
layout: post
title:  "플로이드 순환 찾기 알고리즘 Floyd's Cycle Detection Algorithm"
image: ''
date:   2018-01-27 04:00:00
tags:
- c
- algorithm
- floyd
description: ''
categories:
- Algorithm
---

<img src="https://octodex.github.com/images/codercat.jpg" alt="">

어떤 연결리스트가 주어졌을때 해당 연결리스트가 null로 끝나는지 순환이 되는지를 검사하는 방법엔 무엇이 있을까?

주어진 연결리스트가 완전한 환형이라면 쉽게 순환 여부를 알 수 있을 것이다. 주어진 연결리스트가 완전 환형이 아니라면 순환을 찾기 위해서는 2개의 노드가 가리키는 노드를 찾는 것이 핵심이다.

물론 해시테이블을 이용해서 순환여부를 검사할 수 있겠지만 이번 시간에는 플로이드 순환 찾기 알고리즘을 이용해서 풀어보고자 한다.


#Floyd's Cycle Detection Algorithm

기본 개념은 이러하다. 

속도가 다른 두개의 포인터를 루프에 진입시켜 진행하다보면 순환일 경우 결국 같은 노드를 가르키게 된다는 심플한 개념이다.

{% highlight c %}
int containsLoop(node *head){
    node *slowptr=head, *fastptr=head;
    while(fastptr&&fastptr->next){
        slowptr = slowptr->next;
        fastptr = fastptr->next->next;
        if(fastptr==slowptr)
            return 1;
    }
    return 0;
}
{% endhighlight %}

slowpt은 한 번에 1칸씩 전진하며 fastptr은 한 번에 2칸씩 전진한다. 주어진 그래프가 순환이 아닐경우 그끝에 NULL을 만나 반복문이 종료되고 0을 반환함으로써 순환이 아님을 알 수 있고 순환이라면 결국 slowptr과 fastptr이 만나게 되어 1를 반환한다.

그렇다면 순환점을 찾는 방법은 무엇이 있을까?

정답은 플로이드 순환 찾기 알고리즘을 확장하면 된다.

{% highlight c %}
int findLoopPoint(node *head){
    node *slowptr=head, *fastptr=head;
    int loop=0;
    while(fastptr&&fastptr->next){
        slowptr = slowptr->next;
        fastptr = fastptr->next->next;
        if(fastptr==slowptr){
            loop=1;
            break;
        }
    }
    if(loop){
        slowptr = head;
        while(slowptr!=fastptr){
            fastptr = fastptr->next;
            slowptr = slowptr->next;
        }
        return fastptr->data;
    }
    return 0;
}
{% endhighlight %} 

플로이드 순환 찾기 알고리즘으로 순환을 찾게되면 루프내에서 slowptr과 fastptr이 만나게 되는 노드가 head로부터 다시 시작할때 순환이 시작되는 노드와의 거리가 같게 된다.

그래서 순환 찾기가 종료되는 시점에 노드의 위치를 fastptr에 그냥 냅두고 slowptr의 위치를 head로 초기화 한 뒤 서로 한칸씩 전진해서 다시 만나게 되는 지점이 바로 순환이 시작되는 노드가 된다.

플로이드의 거북이와 토끼 문서를 참고해보면 자세히 확인할 수 있다. <a href="https://en.wikipedia.org/wiki/Cycle_detection#Floyd's_Tortoise_and_Hare">Floyd's_Tortoise_and_Hare</a>
