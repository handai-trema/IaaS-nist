var http = require('http');
var socketio = require('socket.io');
var chokidar = require('chokidar');
var fs = require('fs');

var server = http.createServer(function (req, res) {
  var url = req.url;
  if('/' == url){
  
        fs.readFile('../VMmanager/akan.html', 'utf-8', function(err, data) {
        if (err) {
            res.writeHead(404, {'Content-Type': 'text/plain'});
            res.write('not found!');
            return res.end();
        }
        res.writeHead(200, {'Content-Type': 'text/html'});
        res.write(data);
        res.end();
        });
  } else if('/vis.js' == url) {
    fs.readFile('./vis.js', 'UTF-8', function(err, data){
      response.writeHead(200, {'Content-Type': 'text/javascript'});
      response.write(data);
      response.end();
    });
  } else if('/vis.css' == url) {
    fs.readFile('./vis.css', 'UTF-8', function(err, data){
      response.writeHead(200, {'Content-Type': 'text/css'});
      response.write(data);
      response.end();
    });
  } else if('/switch.jpg' == url) {
    fs.readFile('./switch.jpg', function(err, data) {
      response.writeHead(200, {'Content-Type': 'image/jpeg'});
      response.end(data);
    });
  } else if('/host.jpg' == url) {
    fs.readFile('./host.jpg', function(err, data) {
      response.writeHead(200, {'Content-Type': 'image/jpeg'});
      response.end(data);
    });
  }
}).listen(8174);

console.log('Server running at http://127.0.0.1:8174/');

var watcher = chokidar.watch('./watched/',{
  ignored:/[\/\\]\./,
  persistent:true
});

var io = socketio.listen(server);

watcher.on('ready', function(){

  // 準備完了
  console.log("Start watching.");

  // ファイルの追加
  watcher.on('add', function(path){
    console.log(path+" added.");
  });

  // ファイルの編集
  watcher.on('change', function(path){
    console.log(path+" changed.");
    var rs = fs.createReadStream('./watched/path.txt');
    var readline = require('readline');
    var rl = readline.createInterface(rs, {});
    var sp = [];
    rl.on('line', function(line) {
      sp = line.split(" ");
    }).on('close', function(){
      io.sockets.emit('server_to_client', {value:sp});
    });
  });

});


io.sockets.on('connection', function(socket) {
  console.log("connected.");
  socket.on('create', function(data) {
    console.log(data);
  });
});
