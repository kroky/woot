class @Woot.QuillAdapter
  colors: ['rgba(139,0,139,0.4)', 'rgba(255,127,0,0.4)', 'rgba(238,44,44,0.4)', 'rgba(179,238,58,0.4)', 'rgba(28,134,238,0.4)']

  constructor: (socket, editor_id, toolbar_id, authors_id = null) ->
    @socket = socket
    @site_id = Math.floor((Math.random() * 999) + 1)
    @color = @colors[Math.floor(Math.random() * 5)]
    @editor = new Quill editor_id,
      modules:
        'authorship':
          authorId: 'Author'+@site_id
          enabled: true
        'multi-cursor':
          timeout: 7000
        'toolbar':
          container: toolbar_id
        'link-tooltip': true
      theme: 'snow'
    @site = new Woot.Site(this)
    if authors_id?
      @authors = $(authors_id)
      @authors.append('<div style="background-color: '+@color+'">Author'+@site_id+' - me</div>')
    @socket.emit 'woot_send',
      type: 'cursor-create'
      id: @site_id
      color: @color
      sender: @site_id
      state: null
    @editor.on 'text-change', @textChange
    # Sync editor's cursor location
    @editor.on 'selection-change', @selectionChange

  textChange: (delta, source) =>
    #console.log [source, delta]
    return if source != 'user'
    index = 0
    last_retain = 0
    l = 0
    for op, di in delta.ops
      if op.start or op.end
        # retain op
        # delete missing retains
        while( last_retain < op.start )
          #console.log(['generateDel', index+1, last_retain, delta.startLength])
          @site.generateDel(index+1)
          last_retain++
        # special case of trailing new line char
        op.end-- if op.end == delta.startLength
        if $.isEmptyObject(op.attributes)
          # increment kept chars
          index += op.end - op.start
        else
          # apply attributes and increment kept chars
          for j in [op.start..op.end-1] by 1
            @site.generateAttrib(++index, op.attributes)
        last_retain = op.end
        last_retain++ if op.end == delta.startLength-1
      else
        # insert
        length = op.value.length;
        # don't sync the trailing new line char as it is automatically added by quill on the other side
        length-- if delta.startLength == 0 and di == delta.ops.length-1
        for i in [0..length-1] by 1
          #console.log(['generateIns', index, op.value.charAt(i), i, length])
          @site.generateIns(index, op.value.charAt(i), op.attributes)
          #console.log(window.site.value())
          index++
    for i in [last_retain..delta.startLength-1] by 1
      #console.log(['generateDel', index, i, delta.startLength])
      @site.generateDel(index)

  selectionChange: (range) =>
    if range
      @socket.emit 'woot_send',
        type: 'cursor-change'
        id: @site_id
        char: @site.ithVisible(range.end)
        sender: @site_id

  cursorCreate: (op) =>
    author = 'Author'+op.id
    unless @editor.getModule('multi-cursor').cursors[author]
      @editor.getModule('authorship').addAuthor(author, op.color);
      @editor.getModule('multi-cursor').setCursor(author, @editor.getLength()-1, author, op.color);
      if op.state and @site.empty()
        @site.string = op.state.string
        @site.chars_by_id = op.state.chars_by_id
        @site.pool = op.state.pool
        ops = []
        for el in @site.string
          continue unless el.v and el.c
          ops.push
            value: el.c
            attributes: el.a
        @editor.updateContents
          startLength: 0
          endLength: ops.length
          ops: ops
      if @site_id != op.sender
        @socket.emit 'woot_send',
          type: 'cursor-create'
          id: @site_id
          color: @color
          sender: op.sender
          state:
            string: @site.string
            chars_by_id: @site.chars_by_id
            pool: @site.pool
      if @authors?
        @authors.append('<div style="background-color: '+op.color+'">'+author+'</div>')

  cursorChange: (op) =>
    author = 'Author'+op.id
    pos = @site.visiblePos(op.char)
    @editor.getModule('multi-cursor').moveCursor(author, pos+1)

  attrib: (op) =>
    pos = @site.visiblePos(op.char)
    contents = @site.value()
    length = contents.length
    ops = []
    ops.push({ start: 0, end: pos }) if pos > 0
    ops.push({ start: pos, end: pos+1, attributes: op.attribs })
    ops.push({ start: pos+1, end: length+1}) if pos < length
    #console.log([length, op, contents, ops])
    @editor.updateContents
      startLength: length+1
      endLength: length+1
      ops: ops

  del: (op) =>
    pos = @site.visiblePos(op.char)+1
    contents = @site.value()
    length = contents.length+1
    #console.log([length, contents, op])
    ops = []
    ops.push({ start: 0, end: pos-1 }) if pos > 0
    ops.push({ start: pos, end: length+1 }) if pos <= length
    #console.log [length, pos, ops]
    @editor.updateContents
      startLength: length+1
      endLength: length
      ops: ops

  ins: (op) =>
    pos = @site.visiblePos(op.char)
    contents = @site.value()
    length = contents.length
    length = 0 if length == 1
    #console.log [length, contents, op]
    ops = []
    ops.push({ start: 0, end: pos }) if pos > 0
    ops.push({ value: op.char.c, attributes: op.char.a })
    ops.push({ start: pos, end: length }) if pos < length
    #console.log [length, pos, ops]
    @editor.updateContents
      startLength: length
      endLength: length+1
      ops: ops

  contentsInit: (contents) =>
    @editor.setHTML(contents)
    @textChange(@editor.getContents(), 'user')

  contents: =>
    @editor.getHTML()
