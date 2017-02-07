var http = require('http');
var socketio = require('socket.io');
var exec = require('child_process').exec;
var fs = require('fs');

var io = require('socket.io-client');
var socket = io("http://localhost:8174");

socket.on('connect', function(data){
  console.log("kita?");
  socket.emit('message',"kitaka?");
});
