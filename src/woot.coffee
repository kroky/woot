Woot = exports? and exports or @Woot = {}

class Woot.Site
  
  start:
    id: [0, 0]
    v: true
    c: ''
    a: {}
    p: null
    n: [999, 999]
  end:
    id: [999, 999]
    v: true
    c: ''
    a: {}
    p: [0, 0]
    n: null
  
  constructor: (editor) ->
    @num = editor?.site_id
    @socket = editor?.socket
    @editor = editor
    @h = 0
    @string = [@start, @end]
    @chars_by_id = {}
    @chars_by_id['s'+@start.id[0]+'c'+@start.id[1]] = @start
    @chars_by_id['s'+@end.id[0]+'c'+@end.id[1]] = @end
    @pool = []
    @dirty = false
    if @socket?
      @socket.on 'woot_receive', @receive
      setInterval @autosave, 10000

  extend: (object, properties) ->
    for key, val of properties
      object[key] = val
    object

  empty: =>
    @string.length == 2

  pos: (c) =>
    for el, i in @string
      return i if c.id[0] == el.id[0] and c.id[1] == el.id[1]
    return -1

  visiblePos: (c) =>
    pos = -1
    for el, i in @string
      return pos if c.id[0] == el.id[0] and c.id[1] == el.id[1]
      pos++ if el.v
    return -1

  insert: (c, p) =>
    for i in [(@string.length-1)..p]
      @string[i+1] = @string[i]
    @string[p] = c
    @chars_by_id['s'+c.id[0]+'c'+c.id[1]] = c

  subseq: (c, d) =>
    sub = []
    start = @pos(c)
    end = @pos(d)
    if start+1 <= end-1 and start > -1 and end > -1
      for i in [(start+1)..(end-1)]
        sub.push(@string[i])
    sub

  contains: (id) =>
    for el in @string
      return true if el.id[0] == id[0] and el.id[1] == id[1]
    false

  value: =>
    visible = ''
    for el in @string
      visible += el.c if el.v
    visible

  ithVisible: (i) =>
    p = 0
    for el in @string
      return el if el.v and p++ is i
    return null

  generateIns: (pos, char, attribs = {}) =>
    @h += 1
    cp = @ithVisible(pos)
    cn = @ithVisible(pos+1)
    #unless cn?
    #  console.log(pos)
    #  console.log @string
    c =
      id: [@num, @h]
      v: true
      c: char
      a: attribs
      p: cp.id
      n: cn.id
    @integrateIns(c, cp, cn)
    @socket.emit 'woot_send', {type: 'ins', char: c, sender: @num}

  generateDel: (pos) =>
    c = @ithVisible(pos)
    c.v = false
    @socket.emit 'woot_send', {type: 'del', char: c, sender: @num}
    @dirty = true

  generateAttrib: (pos, attribs) =>
    c = @ithVisible(pos)
    @extend( c.a, attribs )
    @socket.emit 'woot_send', {type: 'attrib', char: c, attribs: attribs, sender: @num}
    @dirty = true

  integrateAttrib: (c, attribs) =>
    @extend( @string[@pos(c)].a, attribs )
    @dirty = true

  integrateDel: (c) =>
    @string[@pos(c)].v = false
    @dirty = true

  integrateIns: (c, cp, cn) =>
    sub = @subseq(cp, cn)
    if sub.length == 0
      @insert(c, @pos(cn))
    else
      l = []
      l.push cp
      cp_pos = @pos(cp)
      cn_pos = @pos(cn)
      for d in sub
        p_pos = @pos(@chars_by_id['s'+d.p[0]+'c'+d.p[1]])
        n_pos = @pos(@chars_by_id['s'+d.n[0]+'c'+d.n[1]])
        if p_pos <= cp_pos and cn_pos <= n_pos
          l.push d
      l.push cn
      i = 1
      while( i < l.length-1 and (l[i].id[0] < c.id[0] or (l[i].id[0] == c.id[0] and l[i].id[1] < c.id[1])) )
        i += 1
      @integrateIns(c, l[i-1], l[i])
    @dirty = true

  isExecutable: (op) =>
    if op.type == 'cursor-create' or op.type == 'contents-init'
      true
    else if op.type == 'del' or op.type == 'attrib' or op.type == 'cursor-change'
      @contains(op.char.id)
    else
      @contains(op.char.p) and @contains(op.char.n)

  receive: (op) =>
    return if op.sender and op.sender == @num
    if @isExecutable(op)
      @execute(op)
    else
      @pool.push(op)
    new_pool = []
    while op = @pool.shift()
      new_pool.push(op) unless @execute(op)
    @pool = new_pool

  execute: (op) =>
    if @isExecutable(op)
      if op.type == 'contents-init'
        @editor?.contentsInit(op.contents)
      else if op.type == 'cursor-create'
        @editor?.cursorCreate(op)
      else if op.type == 'cursor-change'
        @editor?.cursorChange(op)
      else if op.type == 'attrib'
        @integrateAttrib( op.char, op.attribs )
        @editor?.attrib(op)
      else if op.type == 'del'
        @integrateDel(op.char)
        @editor?.del(op)
      else
        cp = @chars_by_id['s'+op.char.p[0]+'c'+op.char.p[1]]
        cn = @chars_by_id['s'+op.char.n[0]+'c'+op.char.n[1]]
        @integrateIns(op.char, cp, cn)
        @editor?.ins(op)
      return true
    else
      return false

  autosave: =>
    return unless @dirty
    @socket.emit 'woot_save', @editor.contents()
    @dirty = false


# s1 = new Site(1)
# s2 = new Site(2)
# s3 = new Site(3)
# s1.generateIns(0, '1')
# s2.generateIns(0, '2')
# s3.receive({type: 'ins', char: s1.ithVisible(1)})
# s2.receive({type: 'ins', char: s1.ithVisible(1)})
# s3.generateIns(0, '3')
# s3.generateIns(2, '4')
# s3.receive({type: 'ins', char: s2.ithVisible(2)})
# s2.receive({type: 'ins', char: s3.ithVisible(1)})
# s2.receive({type: 'ins', char: s3.ithVisible(4)})
# s1.receive({type: 'ins', char: s3.ithVisible(1)})
# s1.receive({type: 'ins', char: s3.ithVisible(4)})
# s1.receive({type: 'ins', char: s2.ithVisible(3)})
# console.log(s1.value())
# console.log(s2.value())
# console.log(s3.value())
