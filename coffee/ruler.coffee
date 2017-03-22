# 00000000   000   000  000      00000000  00000000   
# 000   000  000   000  000      000       000   000  
# 0000000    000   000  000      0000000   0000000    
# 000   000  000   000  000      000       000   000  
# 000   000   0000000   0000000  00000000  000   000  
{
sw,sh,
setStyle,
last,
$}        = require './tools/tools'
keyinfo   = require './tools/keyinfo'
prefs     = require './tools/prefs'
drag      = require './tools/drag'
elem      = require './tools/elem'
pos       = require './tools/pos'
log       = require './tools/log'
str       = require './tools/str'
Loupe     = require './loupe'
pkg       = require '../package'
_         = require 'lodash'
electron  = require 'electron'
path      = require 'path'
screen    = electron.screen
ipc       = electron.ipcRenderer
remote    = electron.remote
browser   = remote.BrowserWindow
win       = remote.getCurrentWindow()
ctrl      = null
horz      = null
vert      = null
horzLines = null
vertLines = null
loupe     = null
mousePos  = pos 0, 0
skipMouse = false
skipTimer = null
origin    = 'outside'
offset    = 0

ipc.on 'setActive', (event, active) -> setActive active
ipc.on 'capture', -> copyImage()
   
# 000   000  000  000   000  00     00   0000000   000  000   000  
# 000 0 000  000  0000  000  000   000  000   000  000  0000  000  
# 000000000  000  000 0 000  000000000  000000000  000  000 0 000  
# 000   000  000  000  0000  000 0 000  000   000  000  000  0000  
# 00     00  000  000   000  000   000  000   000  000  000   000  

winMain = () ->
    window.win = win
    
    prefs.init()
    
    win.on 'move', -> doSkipMouse()
    
    horz =$ 'horz' 
    vert =$ 'vert'
    ctrl =$ 'ctrl'
    horzLines =$ '.horizontal.lines'
    vertLines =$ '.vertical.lines'
    ctrl.focus()
    stopEvent = (e) -> 
        doSkipMouse 0
        e.preventDefault()
        e.stopPropagation() 
        e.stopImmediatePropagation()
        
    horz.addEventListener 'mousedown', stopEvent, true
    vert.addEventListener 'mousedown', stopEvent, true
    ctrl.addEventListener 'mousedown', stopEvent, true
    horz.addEventListener 'mouseup', -> doSkipMouse 10
    vert.addEventListener 'mouseup', -> doSkipMouse 10
    ctrl.addEventListener 'mouseup', -> doSkipMouse 10
        
    window.requestAnimationFrame animationFrame
            
    initRulers()
    initDrag()
    resize()
    loupe = new Loupe
    
    setOrigin prefs.get 'origin', 'outside'
    s = prefs.get 'scheme', 'dark.css'
    setScheme s
     
animationFrame = ->
    screenPos = pos screen.getCursorScreenPoint()
    if not skipMouse and not mousePos.equals screenPos
        mousePos = screenPos
        onMousePos mousePos
    window.requestAnimationFrame animationFrame

doSkipMouse = (delay=500) ->
    skipMouse = true
    clearTimeout skipTimer
    updateMouse = ->
        skipMouse = false
        mousePos = pos screen.getCursorScreenPoint()
        onMousePos mousePos
    if delay
        skipTimer = setTimeout updateMouse, delay 

setActive = (active) ->
    if active
        setStyle "#ctrl", "background-blend-mode", "normal"
        setStyle "#body", "opacity", 1
        showCursor = ->
            loupe.refreshDesktop()
            $('cursor').style.display = 'unset'
        setTimeout showCursor, 300
    else
        setStyle "#ctrl", "background-blend-mode", "soft-light"
        setStyle "#body", "opacity", 0.65
        $('cursor').style.display = 'none'
    
# 00000000   000   000  000      00000000  00000000    0000000  
# 000   000  000   000  000      000       000   000  000       
# 0000000    000   000  000      0000000   0000000    0000000   
# 000   000  000   000  000      000       000   000       000  
# 000   000   0000000   0000000  00000000  000   000  0000000   

initRulers = ->
    for x in [0..5000/5]
        
        line = elem class:'line horizontal'
        line.style.transform = "translateX(#{x*5-1}px)"
            
        for n in [20, 10, 2]
            if x % n == 0 
                line.classList.add "_#{n*5}" 
                if x > 0 and n > 2
                    line.appendChild elem class:'num', text: x*5
                break
                
        horzLines.appendChild line
        
    for y in [0..5000/5]
        
        line = elem class:'line vertical'
        line.style.transform = "translateY(#{y*5-1}px)"
            
        for n in [20, 10, 2]
            if y % n == 0 
                line.classList.add "_#{n*5}" 
                if y > 0 and n > 2
                    line.appendChild elem class:'num', text: y*5
                break
                
        vertLines.appendChild line

# 0000000    00000000    0000000    0000000   
# 000   000  000   000  000   000  000        
# 000   000  0000000    000000000  000  0000  
# 000   000  000   000  000   000  000   000  
# 0000000    000   000  000   000   0000000   

initDrag = ->
    
    new drag
        target:  document.body
        onStart: (drag, event) =>

            absPos = pos event
            
            info = elem id: 'info', children: [
                elem id: 'posx', text: "x #{absPos.x - offset}"
                elem id: 'posy', text: "y #{absPos.y - offset}"
                elem id: 'rctw', text: "w 1"
                elem id: 'rcth', text: "h 1"
                ]
            info.style.left = "#{absPos.x}px"
            info.style.top  = "#{absPos.y}px"
            document.body.appendChild info
            
            rect =$ 'rect'
            rect.style.display = 'initial'
            rect.style.left    = "#{absPos.x-1}px"
            rect.style.top     = "#{absPos.y-1}px"
            rect.style.width   = "1px"
            rect.style.height  = "1px"
            
            loupe.setRect w:1, h:1
            
        onMove: (drag, event) => 

            absPos = pos event
            
            info =$ 'info'
            posx =$ 'posx'
            posy =$ 'posy'
            rect =$ 'rect'
            rctw =$ 'rctw'
            rcth =$ 'rcth'
            
            w = drag.deltaSum.x
            h = drag.deltaSum.y
                        
            info.style.left = "#{absPos.x}px"
            info.style.top  = "#{absPos.y}px"

            tl = drag.startPos.min drag.pos
            rect.style.left   = "#{tl.x-1}px"            
            rect.style.top    = "#{tl.y-1}px"
            rect.style.width  = "#{Math.abs(w)+1}px"
            rect.style.height = "#{Math.abs(h)+1}px"
            
            absPos.sub pos offset, offset
            posx.textContent = "x #{absPos.x}"
            posy.textContent = "y #{absPos.y}"
            rctw.textContent = "w #{w+(w < 0 and -1 or 1)}"
            rcth.textContent = "h #{h+(h < 0 and -1 or 1)}"

            loupe.setRect w:w, h:h            
            
        onStop: =>
            rect =$ 'rect'
            rect.style.display = 'none'
            $('info')?.remove()
            loupe.setRect w:0, h:0

# 00000000   00000000   0000000  000  0000000  00000000
# 000   000  000       000       000     000   000     
# 0000000    0000000   0000000   000    000    0000000 
# 000   000  000            000  000   000     000     
# 000   000  00000000  0000000   000  0000000  00000000

screenSize = -> electron.screen.getPrimaryDisplay().workAreaSize
window.onresize = -> resize()
resize = ->
    $('width').textContent  = win.getBounds().width  - offset
    $('height').textContent = win.getBounds().height - offset

copyImage = -> 
    rect =$ 'rect'
    br = rect.getBoundingClientRect()
    if br.width and br.height
        ipc.send 'copyImage', x:br.left, y:br.top, width:br.width, height:br.height
    else
        br = win.getBounds()
        ipc.send 'copyImage', x:offset, y:offset, width:br.width - offset, height:br.height - offset

#  0000000   00000000   000   0000000   000  000   000  
# 000   000  000   000  000  000        000  0000  000  
# 000   000  0000000    000  000  0000  000  000 0 000  
# 000   000  000   000  000  000   000  000  000  0000  
#  0000000   000   000  000   0000000   000  000   000  

toggleOrigin = ->
    setOrigin origin == 'outside' and 'inside' or 'outside'
    
setOrigin = (o) ->
    origin = o
    offset = origin == 'inside' and 22 or 0
    prefs.set 'origin', origin
    h =$ '.origin.line.horizontal'
    v =$ '.origin.line.vertical'
    horz.style.marginLeft = "#{offset}px"
    vert.style.marginTop  = "#{offset}px"
    if origin == 'inside'
        h.style.right  = '0'
        h.style.left   = 'unset'
        v.style.top    = 'unset'
        v.style.bottom = '0'
    else
        h.style.right  = 'unset'
        h.style.left   = '-1px'
        v.style.top    = '-1px'
        v.style.bottom = 'unset'
    resize()

#  0000000  000000000  000   000  000      00000000  
# 000          000      000 000   000      000       
# 0000000      000       00000    000      0000000   
#      000     000        000     000      000       
# 0000000      000        000     0000000  00000000  

toggleScheme = ->
    link =$ 'style-link' 
    currentScheme = last link.href.split('/')
    schemes = ['dark.css', 'bright.css']
    nextSchemeIndex = ( schemes.indexOf(currentScheme) + 1) % schemes.length
    nextScheme = schemes[nextSchemeIndex]
    ipc.send 'setScheme', path.basename nextScheme, '.css'
    prefs.set 'scheme', nextScheme
    setScheme nextScheme
    
setScheme = (style) ->
    link =$ 'style-link' 
    newlink = elem 'link', 
        rel:  'stylesheet'
        type: 'text/css'
        href: "css/#{style}"
        id:   'style-link'

    link.parentNode.replaceChild newlink, link

# 00     00   0000000   000   000  00000000  000   000  000  000   000  
# 000   000  000   000  000   000  000       000 0 000  000  0000  000  
# 000000000  000   000   000 000   0000000   000000000  000  000 0 000  
# 000 0 000  000   000     000     000       000   000  000  000  0000  
# 000   000   0000000       0      00000000  00     00  000  000   000  

moveWin = (key, mod) ->
    
    x = switch key
        when 'left'  then -1
        when 'right' then  1
        else 0
        
    y = switch key
        when 'up'    then -1
        when 'down'  then  1
        else 0
        
    switch mod
        when 'ctrl+shift',    'ctrl'    then x *= 10;  y *= 10
        when 'alt+shift',     'alt'     then x *= 50;  y *= 50
        when 'command+shift', 'command' then x *= 100; y *= 100
        
    switch mod
        when 'shift', 'ctrl+shift', 'alt+shift', 'command+shift' then size = true
        
    b = win.getBounds()
    if size
        b.width  += x
        b.height += y
    else
        b.x += x
        b.y += y
        
    win.setBounds b

# 00     00   0000000   000   000   0000000  00000000  
# 000   000  000   000  000   000  000       000       
# 000000000  000   000  000   000  0000000   0000000   
# 000 0 000  000   000  000   000       000  000       
# 000   000   0000000    0000000   0000000   00000000  

onMousePos = (p) ->
    return if skipMouse
    b = win.getBounds()

    x = p.x - b.x 
    y = p.y - b.y 
    
    loupe?.moveTo p, pos x, y
        
    h =$ '.needle.line.horizontal' 
    v =$ '.needle.line.vertical' 
    h.style.left = "#{x - offset}px"
    v.style.top  = "#{y - offset}px"
    
    c =$ 'cursor' 
    c.style.left = "#{x}px"
    c.style.top  = "#{y}px"
    
    nx =$ '.needle.horizontal .num'
    ny =$ '.needle.vertical .num'
    nx.textContent = x-offset+1
    ny.textContent = y-offset+1

# 000   000  00000000  000   000
# 000  000   000        000 000 
# 0000000    0000000     00000  
# 000  000   000          000   
# 000   000  00000000     000   

document.onkeydown = (event) ->
    {mod, key, combo} = keyinfo.forEvent event

    return if not combo

    switch key
        when 'left', 'right', 'up', 'down' then moveWin key, mod
        when '-'                then loupe.decreaseZoom()
        when '='                then loupe.increaseZoom()
        when '0', 'l'           then loupe.toggle()
    
    switch combo
        when 'command+c', 'c'   then copyImage()
        when 'esc'              then win.close()
        when 'i'                then toggleScheme()
        when 'o'                then toggleOrigin()
        when 'command+alt+i'    then win.webContents.openDevTools()
        
winMain()
