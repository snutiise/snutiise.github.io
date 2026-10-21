---
layout: post
title: "Implementing Git Page Features with Firebase Cloud Functions"
date:   2018-01-28 10:00:00
categories:
- Git
tags:
- firebase
- git
- blog
ko_sha: dc15a30c90c25fcd437ff816e3f2e02ee629d538
---

I wanted to add a feature like a visitor counter to my Git blog.

However, a Git page is a static site, so implementing anything on the server side requires a personal server or a cloud service.

While I was wondering whether to set up a Node.js server on my own machine to handle communication with the Git blog, I came across Firebase.

## What is Firebase?


>Firebase provides a real-time database and backend as a service. The service gives application developers an API that lets them synchronize application data across clients and store it in Firebase's cloud. *(translated from Korean)*

Free users have limits on storage, traffic, and performance, but they are enough for personal use. For the details of the limits, click <a href="https://firebase.google.com/pricing/?hl=ko">here</a>!

To start, go to <a href="https://firebase.google.com/?hl=ko">https://firebase.google.com/?hl=ko</a>, sign up, and create a project.

If you look around DEVELOP after creating a project, you will find Authentication, Database, Storage, Hosting, and Cloud Functions.

Of these, I used the database and Cloud Functions, which is one of the backend features.

## Cloud Function

>With Cloud Functions for Firebase, you can automatically run backend code in response to events triggered by Firebase features and HTTPS requests. Your code is stored in Google's cloud and runs in a managed environment. Therefore, you do not need to manage and scale your own servers. *(translated from Korean)*

In short, if you write a function, export it, and deploy it, you can run the function by accessing "cloud server url + exported function name".

In other words, you can easily build a simple API server.

{% highlight bash %}
#Install Firebase
$ sudo npm install -g firebase-tools

#Initialize Cloud Functions
$ mkdir ~/firebase
$ cd firebase
$ firebase init functions
{% endhighlight %}

I installed Firebase and initialized the firebase directory for Cloud Functions.

The first time you run firebase, you need to log in. Once you log in with your account ID and password, you can proceed with initialization.

First it asks for the project directory, so choose the project you created beforehand.

Next, it asks whether to use JavaScript or TypeScript for Cloud Functions; I chose JavaScript.

Next it asks whether to use ESLint; I chose no because I did not want to configure it separately.

Finally, it asks whether to install dependencies, so select yes.

Now everything needed to use Cloud Functions is ready.

Inside the initialized directory you will see a directory called functions, and index.js in that directory is where you write Cloud Functions.

{% highlight javascript %}
//index.js
const functions = require('firebase-functions');
//use the database
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

exports.functionName = functions.https.onRequest((req, res) => {
    //read data
    admin.database().ref(path).once('value').then(function(snapshot) {
    });
    //write data set or push
    admin.database().ref(path).set({data:1});
});
{% endhighlight %}

If you write code per export.functionName as above and deploy it, the code is uploaded to the server and the function runs when you access the URL.

The req and res objects are the same as req and res in Node.js Express, so take input from req and use res.send() to return data.

For other features, see the <a href="https://firebase.google.com/docs/database/web/read-and-write?authuser=0">guide</a> or the API documentation.

The way to implement and deploy a function is as follows.

{% highlight bash %}
#Deploy all functions
firebase deploy --only functions

#Deploy only the functionName function
firebase deploy --only functions:functionName
{% endhighlight %}

After a successful deploy, the URL for running the function appears in the console.

It usually follows "https://us-central1-프로젝트명.cloudfunctions.net/함수명".

Now, if you send an Ajax request to that URL from the Git page, you can fetch data according to the function you implemented.

I used Cloud Functions to implement an API that returns the total number of visitors to the blog and, when a menu button is clicked, the user's IP and visit count, and displayed them.

The catch is that I was too lazy to implement duplicate prevention...