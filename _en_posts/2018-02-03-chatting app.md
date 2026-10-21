---
layout: post
title: "Building a Chat App with React"
date:   2018-02-03 12:00:00
categories:
- Programming
tags:
- react
- nodejs
- socket io
ko_sha: b5eb35a03333bd1a198fab526eacc898fb5b3736
---

One weekend, while idling around, I decided to build a chat app with Electron.

I built the basic features of the app with React, but when I built it with Electron to use OS features, the socket in the renderer process disconnected after the first emit...

I still do not know the cause, so for now I decided to port it to the web as a second-best option...

Sockets are the basis of chat, so I looked for a usable web socket library and chose socket.io.

{% highlight bash %}
# Easy environment setup...
$ sudo npm install -g create-react-app

# Install other libraries and eject
$ create-react-app chat
$ cd chat
$ npm install --save socket.io
$ npm install --save mongodb
$ npm install --save express
$ npm run eject
{% endhighlight %}

When I first studied React, I did not use create-react-app and had a hard time setting up everything myself: webpack, HMR, PostCSS, Babel, and so on.

But with create-react-app from Facebook, setup is now easy in one shot...

Create an app with create-react-app appName and run eject, and you can start React easily.

The main app.js is as follows.

{% highlight javascript %}
//app.js
import React, { Component } from 'react';
import './App.css';
import AppChannel from './module/channel/channel';
import AppChattingView from './module/chattingView/chattingView';

class App extends Component {
  constructor(props) {
    super(props);
    this.state = {channel:'snutiise'};
    this.updateChannel = this.updateChannel.bind(this);
  }
  updateChannel(channel){
    this.setState({channel: channel});
  }

  render() {
    return (
      <div className="App">
        <AppChannel channel={this.state.channel} onUpdate={this.updateChannel} />
        <AppChattingView channel={this.state.channel} />
      </div>
    );
  }
}

export default App;
{% endhighlight %}

Since this is a simple channel-based chat, the channel value is the only variable it manages.

I originally planned to manage the channel value in the main process when building with Electron, but I changed it to be managed in app.js.

{% highlight javascript %}
updateChannel(event){
    if(event.target.value!=this.state.channel) this.props.onUpdate(event.target.value);
  }
  keyUpdateChannel(event){
    if(event.keyCode==13) {
      if(event.target.value!=this.state.channel) this.props.onUpdate(event.target.value);
    }
  }
  render() {
    return (
        <header className="Channel-header">
          <h1 className="Channel-title">Welcome to Talkwith</h1>
          <input type="text" className="channel" placeholder="channel name" onBlur={this.updateChannel} onKeyDown={this.keyUpdateChannel}/>
        </header>
    );
  }
{% endhighlight %}

AppChannel only passes the changed value to the parent component when the channel value changes.

I meant to exchange values easily through IPC with Electron in mind, but it only made the code longer.



{% highlight javascript %}
import React, { Component } from 'react';
import { Input } from 'react-bootstrap';
import './chattingView.css';
import img from '../../lovelyz.jpg';

import io from 'socket.io-client';
const socket = io();

class ChattingView extends Component {
    constructor(props) {
        super(props);
        this.state = {msg:'', channel:this.props.channel, chatList:[]};
        this.send = this.send.bind(this);
        this.keysend = this.keysend.bind(this);
        this.inputMSG = this.inputMSG.bind(this);
    }
    componentDidMount(){
        let cursor=this;
        socket.emit('channelJoin', this.state.channel);
        socket.on('receive', function (data) {
            cursor.setState({chatList:cursor.state.chatList.concat([data])});
            document.querySelector(".chattingView-chat").scrollTo(0,document.querySelector(".chattingView-chat").scrollHeight);
        });
    }
    componentWillReceiveProps(changeProps){
        socket.emit('channelLeave', this.state.channel);
        this.setState({channel:changeProps.channel},()=>{
            this.setState({chatList:[]});
            socket.emit('channelJoin', this.state.channel);
        });
    }
    send(){
        socket.emit('send',{msg:this.state.msg, channel:this.state.channel});
        this.setState({msg:''});
        document.querySelector(".inputMsg").value="";
    }
    keysend(event){
        if(event.keyCode==13) {
            socket.emit('send',{msg:this.state.msg, channel:this.state.channel});
            this.setState({msg:''});
            document.querySelector(".inputMsg").value="";
        }
    }
    inputMSG(event) {
        this.setState({ msg: event.target.value });
    }
    render() {
        let list = this.state.chatList.map((item, index) =>{
            let date= new Date(item.chat.date);
            return(
                <div key={index}>
                    {item.chat.ip!=null?
                    <div className="chattingView-header">
                        <div>{item.chat.ip}</div>
                        <div>{date.getFullYear()} {date.getMonth()+1}/{date.getDate()} {date.getHours()}:{date.getMinutes()}:{date.getSeconds()}</div>
                    </div>:null}
                    <div className="chattingView-msg">{item.chat.msg}</div>
                </div>
            )
        });
        return (
            <div className="body">
                <div className="chattingView-chatbox">
                <div className="chattingView-chat">{list}</div>
                </div>
                <div className="input-group chattingView-input">
                    <input type="text" className="form-control inputMsg" placeholder="input message..."  onChange={this.inputMSG} onKeyDown={this.keysend}/>
                    <button type="button" className="btn btn-primary" onClick={this.send}>Send</button>
                </div>
            </div>
        );
    }
}

export default ChattingView;
{% endhighlight %}

Using componentDidMount, it emits the channelJoin event after rendering finishes to join the channel. After that, messages arriving through the receive event are put into chatList and rendered.

When the channel value changes in AppChannel, componentWillReceiveProps detects the props change event from the parent component, emits the channelLeave event to leave the channel, and then emits the channelJoin event with the new channel name.


The server-side code only handles the channelJoin, channelLeave, and receive events.

{% highlight javascript %}
const mongodb =require('mongodb');
const MongoClient = mongodb.MongoClient;
const dbName = 'chatting';
const express = require('express');
const app = express();
const http = require('http').Server(app);
const io = require('socket.io')(http);
app.use('/', express.static(__dirname + '/build'));

io.sockets.on('connection', function (socket) {
    socket.on('channelJoin',function(channel){
        socket.join(channel);
        MongoClient.connect('mongodb://localhost:27017/', function (error, client) {
            if (error) console.log(error);
            else {
                const db = client.db(dbName);
                db.collection('log').find({channel:channel}).sort({data:1}).toArray(function(err,doc){
                    if (err) console.log(err);
                    doc.forEach(function(item){
                        socket.emit('receive', {chat:item});
                    });
                    let msg={msg:socket.handshake.address+"님이 "+channel+" 채널에 입장하셨습니다."};
                    io.to(channel).emit('receive', {chat:msg});
                    client.close();
                });
            }
        });
    });
    socket.on('send', function (data) {
        let dataAddinfo={ip:socket.handshake.address, msg:data.msg, date:Date.now()};
        MongoClient.connect('mongodb://localhost:27017/', function (error, client) {
            if (error) console.log(error);
            else {
                const db = client.db(dbName);
                db.collection('log').insert({ip:dataAddinfo.ip, msg:dataAddinfo.msg, date:dataAddinfo.date, channel:data.channel}, function (err, doc) {
                    if (err) console.log(err);
                    client.close();
                });
            }
        });
        io.to(data.channel).emit('receive', {chat:dataAddinfo});
    });
    socket.on('channelLeave', function(channel){
        socket.leave(channel);
        let msg={msg:socket.handshake.address+"님이 "+channel+" 채널에서 퇴장하셨습니다."};
        io.to(channel).emit('receive', {chat:msg});
    });
});

http.listen(8000, function(){
    console.log('listening on *:8000');
});
{% endhighlight %}

Nothing special: it serves Express and the socket on port 8000, and on channelJoin it sends the existing chat history along with it to that channel.

With more work, I could add scrolling through the existing chat history, whispers, personal profiles, and so on, but first I need to solve the Electron renderer process socket problem.

You can check the finished chat app here. (Added 2026-10: the demo server is down and the domain has expired, so I removed the link.)

