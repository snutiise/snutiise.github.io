---
layout: post
title: "Memory-Efficient Linked List (xor linked list)"
date:   2018-01-15 05:03:31
categories:
- Data Structure
tags:
- xor linked list
ko_sha: 0270d55fbb3a751cf6f03589caae003603d2e6d6
---

## A Memory-Efficient Doubly Linked List

While reading a book, I came across an interesting concept.

It is the "memory-efficient doubly linked list."

A conventional doubly linked list stores both the address of the previous node and the address of the next node.

A memory-efficient doubly linked list, however, uses the following property of exclusive OR to store both the previous and next node addresses in a single pointer variable.

(X⊕Y)⊕Y=X
 

That is, it stores the XOR of the previous node's address and the next node's address in one pointer variable, and whenever access to the previous or next node is needed, it recovers the address through an XOR operation.

 

It is truly a novel approach.

 

I wondered whether there would be a difference in time efficiency, so I tested it myself.

Test creating 10000 nodes

<img src="{{ "/assets/img/2018-01-15-1.png"}}" alt="Console output. node number 10000, memory efficient time 0.463000, time 0.451000" loading="lazy" decoding="async" width="347" height="81">

Test creating 50000 nodes

<img src="{{ "/assets/img/2018-01-15-2.png"}}" alt="Console output. node number 50000, memory efficient time 12.792000, time 12.394000" loading="lazy" decoding="async" width="322" height="81">

Test creating 100000 nodes

<img src="{{ "/assets/img/2018-01-15-3.png"}}" alt="Console output. node number 100000, memory efficient time 66.352997, time 63.189999" loading="lazy" decoding="async" width="328" height="89">

 

I inserted every node at the tail when building the linked list, so this is a worst-case calculation.

 

Looking at the time difference, there seems to be effectively no difference for 10,000 and 50,000 nodes.

For 100,000 nodes, there is a difference of about 3 seconds.

I wondered how much this difference would grow, so I decided to test 150,000 nodes as well.

<img src="{{ "/assets/img/2018-01-15-4.png"}}" alt="Console output. node number 150000, memory efficient time 159.723999, time 154.268997" loading="lazy" decoding="async" width="323" height="81">

The time increased by about 2 seconds compared with 100,000 nodes, which seems acceptable given that the number of nodes grew by 50,000.

## test code

{% highlight c++ %}
typedef struct MEDoubleLinkedList
{
	int data;
	struct MEDoubleLinkedList *ptr;
} MEDoubleLinkedList;

void MEInsertTail(MEDoubleLinkedList **head, int data)
{

	MEDoubleLinkedList* cur = head;
	MEDoubleLinkedList* prev = NULL;
	MEDoubleLinkedList* new = (MEDoubleLinkedList*)malloc(sizeof(MEDoubleLinkedList));

	while ((MEDoubleLinkedList*)((unsigned int)prev ^ (unsigned int)cur->ptr) != NULL)
	{
		MEDoubleLinkedList* temp = cur;

		cur = (MEDoubleLinkedList*)((unsigned int)prev ^ (unsigned int)cur->ptr);

		prev = temp;
	}
	new->data = data;
	new->ptr = (MEDoubleLinkedList*)((unsigned int)cur ^ (unsigned int)NULL);

	cur->ptr = (MEDoubleLinkedList*)((unsigned int)((MEDoubleLinkedList*)(((unsigned int)cur->ptr^ (unsigned int)NULL)))^ (unsigned int)new);
}
{% endhighlight %}


I don't know at what point space efficiency outweighs time efficiency, but it seems like an interesting method.

Of course, now that memory is cheap, it is hard to find much significance in it.

It was first introduced in Linux Journal in 2004!

http://www.linuxjournal.com/article/6828?page=0,0

It was introduced in 2004, but I only saw it for the first time in 2018.