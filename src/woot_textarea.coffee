class @Woot.TextareaAdapter
  constructor: (socket, editor_id, authors_id) ->
    @socket = socket
    @site_id = Math.floor((Math.random() * 999) + 1)
    @editor = $(editor_id)
    @site = new Woot.Site(this)
    @author_ids = {}
    if authors_id?
      @authors = $(authors_id)
      @authors.append('<div>Author'+@site_id+' - me</div>')
      @author_ids[@site_id] = 1
    # used for initial sync
    @socket.emit 'woot_send',
      type: 'cursor-create'
      id: @site_id
      sender: @site_id
      state: null
    @editor.on 'keydown', @keydown
    @editor.on 'keypress', @keypress
    @editor.on 'keyup', @keyup

  keydown: =>
    @orig_length = @editor.val().length

  keypress: (e) =>
    return if e.which != 10 && e.which != 13 && ( e.which < 32 || e.which > 126 )
    @site.generateIns @editor[0].selectionStart, String.fromCharCode(e.which)
  
  keyup: (e) =>
    sel = @editor[0].selectionStart
    length = @editor.val().length
    if e.which == 8 and sel >= 0 and @orig_length > length
      @site.generateDel sel+1
    if e.which == 46 and sel <= length and @orig_length > length
      @site.generateDel sel+1
  
  cursorCreate: (op) =>
    author = 'Author'+op.id
    unless @author_ids[op.id]
      @author_ids[op.id] = 1
      if op.state and @site.empty()
        @site.string = op.state.string
        @site.chars_by_id = op.state.chars_by_id
        @site.pool = op.state.pool
        @update()
      if @site_id != op.sender
        @socket.emit 'woot_send',
          type: 'cursor-create'
          id: @site_id
          sender: op.sender
          state:
            string: @site.string
            chars_by_id: @site.chars_by_id
            pool: @site.pool
      if @authors?
        @authors.append('<div>'+author+'</div>')

  del: (op) =>
    @update()

  ins: (op) =>
    @update()

  contentsInit: (contents) =>
    for char, index in contents
      @site.generateIns(index, char)
    @update()

  update: =>
    editor = @editor[0]
    start = editor.selectionStart
    end = editor.selectionEnd
    scroll = editor.scrollTop
    editor.value = @site.value()
    editor.selectionStart = start
    editor.selectionEnd = end
    editor.scrollTop = scroll

  contents: =>
    @editor.val()
