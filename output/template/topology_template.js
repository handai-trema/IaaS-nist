var nodes = null;
var edges = null;
var network = null;
nodes = [];
// Create a data table with links.
edges = [];
var DIR = './images/';
// Create a data table with nodes.
<% @topology.each do |topology| %>
<%= topology %>
<% end %>
