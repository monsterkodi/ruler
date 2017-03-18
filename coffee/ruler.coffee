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
keyinfo   = require './tools/keyinfo'
drag      = require './tools/drag'
elem      = require './tools/elem'
str       = require './tools/str'
_         = require 'lodash'
electron  = require 'electron'
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
origin    = 'outside'

ipc.on 'setWinID', (event, id) => winMain id
   
# 000   000  000  000   000  00     00   0000000   000  000   000  
# 000 0 000  000  0000  000  000   000  000   000  000  0000  000  
# 000000000  000  000 0 000  000000000  000000000  000  000 0 000  
# 000   000  000  000  0000  000 0 000  000   000  000  000  0000  
# 00     00  000  000   000  000   000  000   000  000  000   000  

winMain = (id) ->
    win = browser.fromId id 
    # win?.webContents.openDevTools()
    horz =$ 'horz' 
    vert =$ 'vert'
    ctrl =$ 'ctrl'
    horzLines =$ '.horizontal.lines'
    vertLines =$ '.vertical.lines'
    ctrl.focus()
    ctrl.onclick = toggleOrigin
    initRulers()
    resize()
    
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

# 00000000   00000000   0000000  000  0000000  00000000
# 000   000  000       000       000     000   000     
# 0000000    0000000   0000000   000    000    0000000 
# 000   000  000            000  000   000     000     
# 000   000  00000000  0000000   000  0000000  00000000

screenSize = -> electron.screen.getPrimaryDisplay().workAreaSize
window.onresize = -> resize()
resize = ->
    o = origin == 'inside' and 22 or 0
    $('width').textContent  = win?.getBounds().width  - o
    $('height').textContent = win?.getBounds().height - o

#  0000000   00000000   000   0000000   000  000   000  
# 000   000  000   000  000  000        000  0000  000  
# 000   000  0000000    000  000  0000  000  000 0 000  
# 000   000  000   000  000  000   000  000  000  0000  
#  0000000   000   000  000   0000000   000  000   000  

toggleOrigin = ->
    origin = origin == 'outside' and 'inside' or 'outside'
    h = $('.origin.line.horizontal')
    v = $('.origin.line.vertical')
    if origin == 'inside'
        horz.style.marginLeft = '22px'
        vert.style.marginTop  = '22px'
        h.style.right  = '0'
        h.style.left   = 'unset'
        v.style.top    = 'unset'
        v.style.bottom = '0'
    else
        horz.style.marginLeft = '0'
        vert.style.marginTop  = '0'
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
        when 'o' then toggleOrigin()
        when 'i' then toggleStyle()
    
    switch combo
        when 'right'            then return move  1,  0
        when 'up'               then return move  0, -1
        when 'down'             then return move  0,  1
        when 'esc'              then return win?.close()
        when 'command+alt+i'    then return win?.webContents.openDevTools()
        

