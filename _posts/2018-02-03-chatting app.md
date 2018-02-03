---
layout: post
title:  "react로 채팅 App만들기"
image: ''
date:   2018-02-03 12:00:00
tags:
- react
- nodejs
- socket io
description: ''
categories:
- React
---

<img src="https://octodex.github.com/images/codercat.jpg" alt="">

주말에 한가롭게 놀다가 electron으로 채팅앱을 만들기로 마음 먹었다.

react를 이용해서 앱의 기본 기능들은 만들었지만 os기능을 이용하고자 electron으로 빌드시 renderer process에서 socket이 최초 emit후 끊어지는 증상이 발생했다...

아직도 원인을 모르겠어서 일단 꿩대신 닭으로 web 포팅하기로 했다...

채팅의 기본은 socket이기 때문에 쓸만한 web socket라이브러리를 찾다가 socket.io를 사용하기로 했다.

{% highlight bash %}
# 간편 환경셋팅...
$ sudo npm install -g create-react-app

# 기타 라이브러리 설치 및 이젝트
$ create-react-app chat
$ cd chat
$ npm install --save socket.io
$ npm install --save mongodb
$ npm install --save express
$ npm run eject
{% endhighlight %}

처음 react를 공부할때는 create-react-app을 사용하지 않고 webpack 설치 및 hmr, postcss, babel 등 직접 설정을 다해주느라 고생을 했다.

하지만 facebook에서 제공하는 create-react-app 요놈 한 방이면 이젠 간편설치...

create-react-app appName으로 앱을 생성하고 eject만 해주면 쉽게 react를 시작할 수 있다.

메인이 되는 app.js는 아래와 같다.

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

간단한 channel 기반 채팅이기 때문에 관리되는 변수는 channel 값 밖에 없다.

channel값의 경우 원래 electron으로 빌드시 main process에서 관리하려고 했지만 app.js에서 관리하도록 수정했다.

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

AppChannel은 단순히 channel 값이 변경될 경우에만 상위 컴포넌트로 변경된 값을 전달하기만한다.

electron을 생각해서 ipc통신을 이용하여 편하게 값을 주고 받으려 그랬는데 코드만 더 길어졌다.



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
                        <div>{date.getFullYear()}년 {date.getMonth()+1}월 {date.getDate()}일 {date.getHours()}:{date.getMinutes()}:{date.getSeconds()}</div>
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
                    <button type="button" className="btn btn-primary" onClick={this.send}>입력</button>
                </div>
            </div>
        );
    }
}

export default ChattingView;
{% endhighlight %}

componentDidMount을 이용해 렌더링이 다 끝난후 channelJoin 이벤트에 emit하여 channel에 입장한다. 이후 receive 이벤트로 오는 메시지를 chatList에 넣어 렌더링하여 보여줄 수 있도록한다.

AppChannel에서 channel 값을 변경할 경우 상위 컴포넌트로부터 props 변경 이벤트를 componentWillReceiveProps로 감지하여 channelLeave 이벤트에 emit하여 채널에서 퇴장한 뒤 변경된 채널명으로 channelJoin 이벤트에 emit한다.


서버쪽 코드는 단순히 channelJoin 및 channelLeave, receive 이벤트만 처리한다.

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

특별한건 없고 8000포트로 express와 socket 서비스를 제공하고 channelJoin시 해당 channel에 기존 채팅기록을 같이 전송해준다.

좀 더 구현하자면 기존 채팅기록에 스크롤링이나 귓속말, 개인 프로필 등 더 작업이 가능하지만 일단은 electron renderer process socket 문제부터 해결해야 겠다.

구현된 채팅앱은 <a href="http://sodeok.xyz:8000">이곳</a>에서 확인 가능하다.

