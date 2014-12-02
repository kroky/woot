var port = 843;

var io = require('socket.io').listen( port );
io.enable('browser client minification');  // send minified client
io.enable('browser client etag');          // apply etag caching logic based on version number
io.enable('browser client gzip');          // gzip the file
//io.set('log level', 1);  

io.sockets.on('connection', function (socket) {
  socket.on('woot_send', function(op){
    socket.broadcast.emit('woot_receive', op);
    if( op.type == 'cursor-create' && Object.keys(io.connected).length == 1 )
      socket.emit('woot_receive', {type: 'contents-init', contents: "Sample initial content that might be coming from permanent storage..."});
  });
  socket.on('woot_save', function(contents){
    console.log(contents);
  });
});
