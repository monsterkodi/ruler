# 000       0000000   000   000  00000000   00000000
# 000      000   000  000   000  000   000  000     
# 000      000   000  000   000  00000000   0000000 
# 000      000   000  000   000  000        000     
# 0000000   0000000    0000000   000        00000000
{
sh,sw,
clamp,
resolve,
setStyle,
$}          = require 'kxk'
childp      = require 'child_process'
electron    = require 'electron'
nativeImage = electron.nativeImage

class Loupe
    
    constructor: () ->
        @desktop = null
        @refreshDesktop()
        @zoom = 0
        @size = 200
        @rect = w:0, h:0
        @offset = x:0, y:0
        @div =$ 'loupe'

    moveTo: (@screenPos, @cursorPos) -> @update()

    setRect: (@rect) -> @updateRect()
        
    update: -> 
        if @zoom > 0
            @size = @zoomLevel() * 100
            hw = parseInt 0.5 * @size / @zoom
            fw = hw*2
            ox = @screenPos.x*2-hw+1
            oy = @screenPos.y*2-hw+1
            x = clamp 0, @desktop?.getSize().width - fw, ox
            y = clamp 0, @desktop?.getSize().height - fw, oy
            @offset = x:x-ox, y:y-oy
            @crop = x:x, y:y, width:fw, height:fw
            @updateCursor()
            @updateRect()
            @updateImage()
        else
            @div.style.display = 'none'

    updateRect: ->
        r =$ 'louperect'
        if @rect.w and @rect.h
            r.style.display = 'initial'
            c = @size/2-@zoom
            if @rect.w > 0
                r.style.right = "#{c}px"
                r.style.left = 'unset'
            else
                r.style.left = "#{c}px"
                r.style.right = 'unset'
            if @rect.h > 0
                r.style.bottom = "#{c}px"
                r.style.top = 'unset'
            else
                r.style.top = "#{c}px"
                r.style.bottom = 'unset'
                
            r.style.width  = "#{(Math.abs(@rect.w)+1)*@zoom*2}px"
            r.style.height = "#{(Math.abs(@rect.h)+1)*@zoom*2}px"
        else
            r.style.display = 'none'

    updateCursor: ->
        b = window.win?.getBounds()
        x = clamp -@cursorPos.x, (b.width  - @size) - @cursorPos.x, -@size/2
        y = clamp -@cursorPos.y, (b.height - @size) - @cursorPos.y, -@size/2

        ox = @offset.x*@zoom
        oy = @offset.y*@zoom
        
        @div.style.display = 'inherit'
        @div.style.left    = "#{x}px"
        @div.style.top     = "#{y}px"
        @div.style.width   = "#{@size}px"
        @div.style.height  = "#{@size}px"
            
        setStyle '.loupe.line.horizontal', 'height', "#{@zoom*16}px"
        setStyle '.loupe.line.horizontal', 'top',    "#{@size/2-@zoom*8-oy}px"
        setStyle '.loupe.line.horizontal', 'left',   "#{@size/2-@zoom-ox}px"
        setStyle '.loupe.line.horizontal', 'width',  "#{@zoom*2}px"
        
        setStyle '.loupe.line.vertical',   'width',  "#{@zoom*16}px"
        setStyle '.loupe.line.vertical',   'left',   "#{@size/2-@zoom*8-ox}px"
        setStyle '.loupe.line.vertical',   'top',    "#{@size/2-@zoom-oy}px"
        setStyle '.loupe.line.vertical',   'height', "#{@zoom*2}px"       
        
    updateImage: ->
        return if not @desktop?
        return if @zoom <= 0
        img = @desktop.crop @crop
        img = img.resize width:@size, height:@size, quality: "good"
        @div.style.background = "url(#{img.toDataURL()})"
        
    refreshDesktop: =>
        tmpFile = resolve '$TMPDIR/ruler_loupe.png'
        childp.exec "screencapture -T 0 -x #{tmpFile}", (err) => 
            if err? then log "[ERROR] screencapture: #{err}"
            @desktop = nativeImage.createFromPath tmpFile

    zoomLevel: -> 
        if @zoom > 0 then Math.log2(@zoom)+1 
        else 0
        
    increaseZoom: -> 
        if @zoom < 16 then @zoom = Math.max(1, @zoom * 2)
        @update()
        
    decreaseZoom: -> 
        @zoom /= 2 
        if @zoom < 1 then @zoom = 0
        @update()
        
    toggle: -> 
        @zoom = @zoom == 0 and 2 or 0
        @update()
        
module.exports = Loupe
