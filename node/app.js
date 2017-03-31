var port = 843;

var io = require('socket.io')( port );

io.on('connection', function (socket) {
  socket.on('room', function(room) {
    socket.join(room);
  });
  socket.on('woot_send', function(op){
    var room = socket.rooms[socket.rooms.length-1];
    socket.in(room).broadcast.emit('woot_receive', op);
    if( op.type == 'cursor-create' && Object.keys(socket.in(room).nsp.sockets).length == 1 )
      socket.in(room).emit('woot_receive', {type: 'contents-init', contents: ""});
  });
  socket.on('woot_save', function(contents){
    var room = socket.rooms[socket.rooms.length-1];
    console.log(room+': '+contents);
  });
});
