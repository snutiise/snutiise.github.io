---
layout: post
title: "Floyd's Cycle Detection Algorithm"
date:   2018-01-27 04:00:00
categories:
- Algorithm
tags:
- algorithm
- floyd
ko_sha: 78bf24b1828ad01776d7842ae6d2e2c5f389ea27
---

Given a linked list, how can we check whether it ends in null or contains a cycle?

If the given linked list is a perfect ring, it is easy to tell whether it cycles. If it is not a perfect ring, the key to finding a cycle is to find the node that 2 nodes point to.

Of course, you could check for a cycle with a hash table, but this time I want to solve it with Floyd's cycle detection algorithm.


## Floyd's Cycle Detection Algorithm

The basic idea is this.

It is a simple idea: if you send two pointers of different speeds into the loop, they will eventually point to the same node when there is a cycle.

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

slowptr advances 1 step at a time and fastptr advances 2 steps at a time. If the given graph has no cycle, the loop ends when it meets NULL at the end and returns 0, which shows there is no cycle; if there is a cycle, slowptr and fastptr eventually meet and it returns 1.

Then how can we find the start of the cycle?

The answer is to extend Floyd's cycle detection algorithm.

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

When Floyd's cycle detection algorithm finds a cycle, the node where slowptr and fastptr meet in the loop is at the same distance from the cycle's start node as the head is.

So at the point where cycle detection ends, leave fastptr where it is, reset slowptr to head, and advance both one step at a time; the point where they meet again is the node where the cycle starts.

For details, see the Floyd's Tortoise and Hare article. <a href="https://en.wikipedia.org/wiki/Cycle_detection#Floyd's_Tortoise_and_Hare">Floyd's_Tortoise_and_Hare</a>
