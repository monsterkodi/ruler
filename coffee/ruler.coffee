# 00000000   000   000  000      00000000  00000000   
# 000   000  000   000  000      000       000   000  
# 0000000    000   000  000      0000000   0000000    
# 000   000  000   000  000      000       000   000  
# 000   000   0000000   0000000  00000000  000   000  
{
sw,sh,
last,
$}        = require './tools/tools'
prefs     = require './tools/prefs'
pos       = require './tools/pos'
keyinfo   = require './tools/keyinfo'
drag      = require './tools/drag'
elem      = require './tools/elem'
str       = require './tools/str'
_         = require 'lodash'
electron  = require 'electron'
screen    = electron.screen
ipc       = electron.ipcRenderer
remote    = electron.remote
browser   = remote.BrowserWindow
log       = -> console.log (str(s) for s in [].slice.call arguments, 0).join " "
win       = null
ctrl      = null
horz      = null
vert      = null
horzLines = null
vertLines = null
mousePos  = pos 0, 0
origin    = 'outside'
offset    = 0

ipc.on 'setWinID', (event, id) => winMain id
   
# 000   000  000  000   000  00     00   0000000   000  000   000  
# 000 0 000  000  0000  000  000   000  000   000  000  0000  000  
# 000000000  000  000 0 000  000000000  000000000  000  000 0 000  
# 000   000  000  000  0000  000 0 000  000   000  000  000  0000  
# 00     00  000  000   000  000   000  000   000  000  000   000  

winMain = (id) ->
    win = browser.fromId id 
    win?.webContents.openDevTools()
    horz =$ 'horz' 
    vert =$ 'vert'
    ctrl =$ 'ctrl'
    horzLines =$ '.horizontal.lines'
    vertLines =$ '.vertical.lines'
    ctrl.focus()
    ctrl.onclick = toggleOrigin
    ctrl.onmousedown = (e) -> e.stopPropagation()
        
    screen.on 'display-metrics-changed', onDisplayChanged
    window.requestAnimationFrame animationFrame
    
    initRulers()
    initDrag()
    resize()
 
animationFrame = ->
    screenPos = pos screen.getCursorScreenPoint()
    if not mousePos.equals screenPos
        mousePos = screenPos
        onMousePos mousePos
    window.requestAnimationFrame animationFrame
    
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
        cursor:  'none'
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
            
            rect = elem id: 'rect'
            rect.style.left = "#{absPos.x-1}px"
            rect.style.top  = "#{absPos.y-1}px"
            rect.style.width = "1px"
            rect.style.height  = "1px"
            document.body.appendChild rect
            
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
            
        onStop: =>
            $('rect')?.remove()
            $('info')?.remove()

# 00000000   00000000   0000000  000  0000000  00000000
# 000   000  000       000       000     000   000     
# 0000000    0000000   0000000   000    000    0000000 
# 000   000  000            000  000   000     000     
# 000   000  00000000  0000000   000  0000000  00000000

screenSize = -> electron.screen.getPrimaryDisplay().workAreaSize
window.onresize = -> resize()
resize = ->
    $('width').textContent  = win?.getBounds().width  - offset
    $('height').textContent = win?.getBounds().height - offset

onDisplayChanged = (event, display, changes) ->
    log "display: #{display}", changes

#  0000000   00000000   000   0000000   000  000   000  
# 000   000  000   000  000  000        000  0000  000  
# 000   000  0000000    000  000  0000  000  000 0 000  
# 000   000  000   000  000  000   000  000  000  0000  
#  0000000   000   000  000   0000000   000  000   000  

toggleOrigin = ->
    origin = origin == 'outside' and 'inside' or 'outside'
    offset = origin == 'inside' and 22 or 0
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
        h.style.left   = '0'
        v.style.top    = '0'
        v.style.bottom = 'unset'
    resize()

#  0000000  000000000  000   000  000      00000000  
# 000          000      000 000   000      000       
# 0000000      000       00000    000      0000000   
#      000     000        000     000      000       
# 0000000      000        000     0000000  00000000  

toggleStyle = ->
    link = $('style-link')
    currentScheme = last link.href.split('/')
    schemes = ['dark.css', 'bright.css']
    nextSchemeIndex = ( schemes.indexOf(currentScheme) + 1) % schemes.length
    newlink = elem 'link', 
        rel:  'stylesheet'
        type: 'text/css'
        href: 'css/'+schemes[nextSchemeIndex]
        id:   'style-link'

    link.parentNode.replaceChild newlink, link

# 00     00   0000000   000   000  00000000  
# 000   000  000   000  000   000  000       
# 000000000  000   000   000 000   0000000   
# 000 0 000  000   000     000     000       
# 000   000   0000000       0      00000000  

move = (key, mod) ->
    
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
        
    b = win?.getBounds()
    if size
        b.width  += x
        b.height += y
    else
        b.x += x
        b.y += y
        
    win?.setBounds b

# 00     00   0000000   000   000   0000000  00000000  
# 000   000  000   000  000   000  000       000       
# 000000000  000   000  000   000  0000000   0000000   
# 000 0 000  000   000  000   000       000  000       
# 000   000   0000000    0000000   0000000   00000000  

onMousePos = (p) ->
    b = win?.getBounds()
    log "#{p.x} #{p.y}"
    x = p.x - b.x 
    y = p.y - b.y 
        
    h =$ '.needle.line.horizontal' 
    v =$ '.needle.line.vertical' 
    h.style.left = "#{x - offset}px"
    v.style.top  = "#{y - offset}px"
    
    c =$ 'cursor' 
    c.style.left = "#{x}px"
    c.style.top  = "#{y}px"

# 000   000  00000000  000   000
# 000  000   000        000 000 
# 0000000    0000000     00000  
# 000  000   000          000   
# 000   000  00000000     000   

document.onkeydown = (event) ->
    {mod, key, combo} = keyinfo.forEvent event

    return if not combo

    switch key
        when 'left', 'right', 'up', 'down' then move key, mod
    
    switch combo
        when 'right'            then return move  1,  0
        when 'up'               then return move  0, -1
        when 'down'             then return move  0,  1
        when 'esc'              then return win?.close()
        when 'i'                then toggleStyle()
        when 'o'                then toggleOrigin()
        when 'command+alt+i'    then return win?.webContents.openDevTools()
        

