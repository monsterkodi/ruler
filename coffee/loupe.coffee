# 000       0000000   000   000  00000000   00000000
# 000      000   000  000   000  000   000  000     
# 000      000   000  000   000  00000000   0000000 
# 000      000   000  000   000  000        000     
# 0000000   0000000    0000000   000        00000000
{
resolve,
$}          = require './tools/tools'
log         = require './tools/log'
elem        = require './tools/elem'
childp      = require 'child_process'
electron    = require 'electron'
nativeImage = electron.nativeImage

class Loupe
    
    constructor: () ->
        @desktop = null
        @refreshDesktop()
        @div =$ 'loupe'
        @div.style.left = "#{-101}px"
        @div.style.top  = "#{-101}px"
    
    moveTo: (p, x, y) ->
        if @desktop?
            rect = x:p.x*2-50, y:p.y*2-50, width:100, height:100
            img = @desktop.crop rect
            img = img.resize width:200, height:200, quality: "good"
            @div.style.background = "url(#{img.toDataURL()})" #"data:image/png;base64,#{img.image}"
        
    refreshDesktop: =>
        tmpFile = resolve '$TMPDIR/ruler_loupe.png'
        childp.exec "screencapture -T 0 #{tmpFile}", (err) => 
            if err? then log "[ERROR] screencapture: #{err}"
            @desktop = nativeImage.createFromPath tmpFile
        
module.exports = Loupe
