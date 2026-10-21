---
layout: post
title: "Recent Update"
date:   2020-11-05 06:00:00
categories:
- Chat
tags:
- daily life
ko_sha: ecb8575358d998a76e75314ca770ad5ed02993e3
---

A recent update...

I finished Software Maestro and now work at a company called Exodus Entertainment.

I work on server development for an idol service called Choeaedol, and because it has many users, I am enjoying the work more than I expected.

Recently, during a big event, I also experienced 5 million MAU.

(The thrill of worrying about the servers every night...)

<a href="{{ "/assets/img/2020-11-05-1.png"}}"><img src="{{ "/assets/img/2020-11-05-1.png"}}" alt="Firebase active users dashboard. 28 days: 4.84 million, 7 days: 2.35 million, 1 day: 1.09 million, and 255,138 users in the last 30 minutes" loading="lazy" decoding="async" width="2022" height="688"></a>
<center>(Users as seen in Firebase)</center>
<br/>
An interesting experience where the mirror server fell behind and the master struggled

(We had legacy code problems and lacked know-how for handling heavy traffic.)
<br/>
<br/>
<br/>
Everyone is sensitive during an event period, so there were some funny reports too.

The service currently runs an L1 cache and an L2 cache. The L1 cache (the cache served from the API server) received cached values a few seconds late, so an overseas user recorded the vote count rising after voting had ended and reported it as vote fraud.

<center><video controls loop muted playsinline preload="none" src="{{ "/assets/img/2020-11-05-2.mp4"}}" alt="" width="300" height="600"/></center>
<center>(Video reported by a user)</center>

<br/>
After riding the big wave of the event, I leveled up a lot and feel proud.



 