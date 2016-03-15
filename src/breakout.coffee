#game status
status = {playing : no, life : 5, hScore : 100, score : 0, speed : 5, ai : no}
# functions
width = -> window.innerWidth or
  document.documentElement.clientWidth or document.body.clientWidth
height = -> window.innerHeight or
  document.documentElement.clientHeight or document.body.clientHeight
createElement = (tag) -> document.createElement(tag)
append = (node) -> document.body.appendChild(node)
px = ((n) -> "#{n}px")
len = (x, y) -> Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2))
#constant
c = {fgColor : '#FFF', bgColor : '#000'}
# class
class Vector2
  x : 0, y : 0
  constructor: (x, y, speed) ->
    if speed? then (if speed is 0 then @x = 0; @y = 0 else _dia = len(x, y)
    @x = x / _dia * speed; @y = y / _dia * speed) else @x = x; @y = y
  change : (x, y, speed) ->
    if speed? then (if speed is 0 then @x = 0; @y = 0; return this else
    _dia = len(x, y); @x = x / _dia * speed; @y = y / _dia * speed; return this)
    else @x = x; @y = y; return this
  speed : (v) ->
    if not v? then return len(@x, @y)
    _dia = len(@x, @y); @x = x / _dia * v; @y = y / _dia * v; return this
class Box
  dom : null, vector : null, width : 10, height : 10,x : 0, y : 0, live : yes
  constructor: (@width, @height, @x, @y) ->
    @dom = createElement('div'); @vector = new Vector2(0,0)
  create : ->
    @update(); append @dom
    @dom.style.position = 'absolute'; @dom.style.backgroundColor = c.fgColor
    return this
  remove : ->
    @dom.remove(); return this
  hit : (o) ->
    _res = no; ox = o.x; oxMax = o.x + o.width; oy = o.y; oyMax = o.y + o.height
    _list = [ox, oy, oxMax, oy, ox, oyMax, oxMax, oyMax]
    i = 0; while i < _list.length
      _res |= (@x < _list[i] < @x + @width) and (@y < _list[i+1] < @y + @height)
      i += 2
    return _res
  reflex : (o) ->
    _x = o.x; _y = o.y; _xMax = o.x+o.width; _yMax = o.y + o.height
    if _x < @x < _xMax then o.vector.x = -Math.abs(o.vector.x)
    if _x < @x + @width < _xMax then o.vector.x = Math.abs(o.vector.x)
    if _y < @y < _yMax then o.vector.y = -Math.abs(o.vector.y)
    if _y < @y + @height < _yMax then o.vector.y = Math.abs(o.vector.y)
    return this
  edge : ->
    if @x < 0 then @vector.x = Math.abs(@vector.x); return 4
    if @x + @width > width() then @vector.x = -Math.abs(@vector.x); return 2
    if @y < 0 then @vector.y = Math.abs(@vector.y); return 1
    if @y + @height > height() then @vector.y = -Math.abs(@vector.y); return 3
    return no
  hide : -> @live = no; @dom.style.display = 'none'; return this
  show : -> @live = yes; @dom.style.display = 'block'; return this
  update : ->
    for p, v of {width: @width, left: @x} then @dom.style[p] = px v
    for p, v of {height: @height, top: @y} then @dom.style[p] = px v
    return this

# stage object
window.stage =
  ball : new Box(10, 10, 0.5 * width() - 5,height() - 50)
  pad : new Box(100, 20, 0.5 * width() - 50,height() - 40)
  allBlock :
    show : -> (for o in block then o.show()); return this
    hide : -> (for o in block then o.hide()); return this
    update : -> (for o in block then o.update()); return this
    create : -> (for o in block then o.create()); return this
    remove : -> (for o in block then o.remove()); return this
block = []; i = 0; while i < 50
  block[i] = new Box(
    width() * 0.09, 20, width() * 0.1 * ((i % 10) + 0.05) , Math.floor(i / 10) *
    (20 + width() * 0.005) + width() * 0.005); i++
# UI
ui = {score: {}, life: {}}
for i of ui
  ui[i] = {dom: createElement('p'), print: (str) -> @dom.innerHTML = str}

# game functions
game =
  init : ->
    document.body.style.backgroundColor = c.bgColor
    document.body.style.overflow = 'hidden'
    for o of stage then stage[o].create()
    window.requestAnimationFrame updateFrame
    ui.score.dom.style.left = 'auto'
    ui.life.dom.style.left = ui.score.dom.style.right = px 5
    ui.life.dom.style.top = ui.score.dom.style.top = px height() - 100
    ui.life.dom.style.color = ui.score.dom.style.color = c.fgColor
    ui.life.dom.style.position = ui.score.dom.style.position = 'absolute'
    ui.score.print 'CLICK TO START THE GAME'; ui.score.print '0 <- SCORE'
    for o in [ui.life.dom, ui.score.dom] then append o; return this
  start : ->
    status.playing = yes; stage.ball.vector.change(-1,-1,status.speed)
    status.life = 5; status.score = 0
    stage.allBlock.show(); logic(); return this
  stop : ->
    status.playing = no; stage.ball.vector.change(0,0)
    ui.life.print 'GAME OVER (CLICK TO RESTART)'; return this

# game logic
logic = ->
  stage.ball.x += stage.ball.vector.x; stage.ball.y += stage.ball.vector.y
  if(stage.ball.edge() is 3) then status.life--
  for o in block
    if (o.hit stage.ball) and o.live
      o.reflex stage.ball; o.hide(); status.score += Math.floor( 0.01 *
      width() * width() / height())
  c = 0; for o in block then if not o.live then c++
  if c >=50 then stage.allBlock.show(); status.score += 50
  if (stage.pad.hit stage.ball)
    stage.pad.reflex stage.ball
    status.score += Math.floor(0.001 * width())
  if status.playing then setTimeout logic, 8
  if status.score > status.hScore then status.hScore = status.score
  if status.life <= 0 then game.stop()
  if status.ai then stage.pad.x = stage.ball.x - 50

# display
resize = ->
  i = 0; while i < 50
    block[i].width = width() * 0.09
    block[i].x = width() * 0.1 * ((i % 10) + 0.05); i++
  stage.pad.y = height() - 40
  ui.life.dom.style.top = ui.score.dom.style.top = px height() - 100
updateFrame = ->
  for o of stage then stage[o].update()
  if status.playing
    ui.score.print "#{status.score} (#{status.hScore}) <- SCORE"
  ui.life.print "LIFE -> #{status.life}"
  return window.requestAnimationFrame updateFrame

# game contral
document.addEventListener 'mousemove', (e) ->
  if status.playing and not status.ai then stage.pad.x = e.clientX - 50
document.addEventListener 'click', (e) ->
  if not status.playing then game.start()
window.addEventListener 'resize', (e) -> window.requestAnimationFrame resize
stage.pad.dom.addEventListener 'click', (e) ->
  status.ai = if status.ai then no else yes

# init
game.init()
