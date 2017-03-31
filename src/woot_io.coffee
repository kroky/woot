class Woot.IO
  constructor: (io) ->
    @io = io

  on: (msg, data) =>
    @io.on(msg, data)

  emit: (msg, data) =>
    @io.emit(msg, data)
