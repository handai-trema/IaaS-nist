var nodes = null;
var edges = null;
var network = null;
nodes = [];
// Create a data table with links.
edges = [];
var DIR = './images/';
// Create a data table with nodes.

nodes.push({id: 1, label: '0x1', image:DIR+'switch.jpg', shape: 'image'});

nodes.push({id: 2, label: '0x2', image:DIR+'switch.jpg', shape: 'image'});

nodes.push({id: 4, label: '0x4', image:DIR+'switch.jpg', shape: 'image'});

nodes.push({id: 3, label: '0x3', image:DIR+'switch.jpg', shape: 'image'});

edges.push({from: 1, to: 3});

edges.push({from: 2, to: 4});

edges.push({from: 1, to: 2});

edges.push({from: 3, to: 2});

nodes.push({id: 172537024438251, label: '9c:eb:e8:0d:5f:eb', image:DIR+'host.png', shape: 'image'});

edges.push({from: 172537024438251, to: 1});

nodes.push({id: 8796754963937, label: '08:00:27:74:6d:e1', image:DIR+'host.png', shape: 'image'});

edges.push({from: 8796754963937, to: 4});

