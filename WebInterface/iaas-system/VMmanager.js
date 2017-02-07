var http = require('http');
var socketio = require('socket.io');
var exec = require('child_process').exec;
var fs = require('fs');

var server = http.createServer(function (req, res) {
  var url = req.url;
  if('/' == url){
        fs.readFile('../VMmanager/index.html', 'utf-8', function(err, data) {
        if (err) {
            res.writeHead(404, {'Content-Type': 'text/plain'});
            res.write('not found!');
            return res.end();
        }
        res.writeHead(200, {'Content-Type': 'text/html'});
        res.write(data);
        res.end();
        });
  } else if(url.match(/.js/)) {
    fs.readFile('../VMmanager'+url, 'UTF-8', function(err, data){
      res.writeHead(200, {'Content-Type': 'text/javascript'});
      res.write(data);
      res.end();
    });
  } else if(url.match(/.css/)) {
    fs.readFile('../VMmanager'+url, 'UTF-8', function(err, data){
      res.writeHead(200, {'Content-Type': 'text/css'});
      res.write(data);
      res.end();
    });
  } else if(url.match(/.jpg/)) {
    fs.readFile('../VMmanager'+url, function(err, data) {
      res.writeHead(200, {'Content-Type': 'image/jpeg'});
      res.end(data);
    });
  } else {
    res.end();
  }
}).listen(8174);

console.log('Server running at http://192.168.1.5:8174/');


var io = socketio.listen(server);

io.sockets.on('connection', function(socket) {
  console.log("connected.");
  socket.emit('ipaddress',socket.handshake.address.slice(7));

  socket.on('create', function(data, fn) {
    console.log(data);
    exec('sh create.sh '+data, (err, stdout, stderr) => {
      if (err) { console.log(err); }
      console.log("VM "+stdout+" を作成しました。");
      fn(stdout); // アドレス入れる
    });
    var i = 2;
    var timerSet = setInterval(function(){
      socket.emit('tsushin',i);
      if(i == 100){
        clearInterval(timerSet);
      }
      i++;
    },1000);
  });
  socket.on('delete', function(data) {
    console.log(data);
    exec('sh stop.sh '+data, (err, stdout, stderr) => {
      if (err) { console.log(err); }
      console.log("VM "+data+" が削除されました。");
    });
  });

  socket.on('webconnect', function(dokoni, darega){
    console.log("クライアント "+darega+" から、Web サイト "+dokoni+" に対する接続要求が来ています。許可する場合は y 許可しない場合は n を押し、Enter を押した後 Ctrl + c を押してください。");

// 標準入力
var yorn;
var reader = require('readline').createInterface({
  input: process.stdin,
  output: process.stdout
});
reader.on('line', function(line) {
  yorn = line;
});
reader.on('close', function() {
    socket.emit('webpermission',yorn);
    // 「重要」接続処理に関するコマンド追加
    if(yorn == "y"){
    exec('sh connect.sh '+dokoni+' '+darega, (err, stdout, stderr) => {
      if (err) { console.log(err); }
      console.log("VM "+data+" が削除されました。");
    });
    } else {
    }

});// 標準入力


  });

});



