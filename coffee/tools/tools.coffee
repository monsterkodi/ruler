# 000000000   0000000    0000000   000       0000000
#    000     000   000  000   000  000      000     
#    000     000   000  000   000  000      0000000 
#    000     000   000  000   000  000           000
#    000      0000000    0000000   0000000  0000000 

pos    = require './pos'
log    = require './log'
_      = require 'lodash'
path   = require 'path'
os     = require 'os'
fs     = require 'fs'

module.exports = 

    # #  0000000   00000000   00000000    0000000   000   000
    # # 000   000  000   000  000   000  000   000   000 000 
    # # 000000000  0000000    0000000    000000000    00000  
    # # 000   000  000   000  000   000  000   000     000   
    # # 000   000  000   000  000   000  000   000     000   

    # last:  (a) -> 
        # if not _.isArray a
            # return a
        # if a?.length
            # return a[a.length-1]
        # null
#         
    # first: (a) ->
        # if not _.isArray a
            # return a
        # if a?.length
            # return a[0]
        # null
    
    # 000   000   0000000   000      000   000  00000000
    # 000   000  000   000  000      000   000  000     
    #  000 000   000000000  000      000   000  0000000 
    #    000     000   000  000      000   000  000     
    #     0      000   000  0000000   0000000   00000000

    clamp: (r1, r2, v) ->
        if r1 > r2
            [r1,r2] = [r2,r1]
        v = Math.max(v, r1) if r1?
        v = Math.min(v, r2) if r2?
        v
            
    # 00000000    0000000   000000000  000   000
    # 000   000  000   000     000     000   000
    # 00000000   000000000     000     000000000
    # 000        000   000     000     000   000
    # 000        000   000     000     000   000
    
    resolve:   (p) -> path.normalize path.resolve p.replace /^\~/, process.env.HOME
    unresolve: (p) -> p.replace os.homedir(), "~"    
    fileName:  (p) -> path.basename p, path.extname p
    extName:   (p) -> path.extname(p).slice 1
    
    fileExists: (file) ->
        try
            if fs.statSync(file).isFile()
                fs.accessSync file, fs.R_OK #| fs.W_OK
                return true
        catch error
            return false

    dirExists: (dir) ->
        try
            if fs.statSync(dir).isDirectory()
                fs.accessSync dir, fs.R_OK
                return true
        catch
            return false
                                                          
    relative: (absolute, to) ->
        return absolute if not absolute?.startsWith '/'
        d = path.normalize path.resolve to.replace /\~/, process.env.HOME
        r = path.relative d, absolute
        if r.startsWith '../../' 
            unresolved = absolute.replace(os.homedir(), "~")
            if unresolved.length < r.length
                r = unresolved
        if absolute.length < r.length    
            r = absolute
        r
        
    swapExt: (p, ext) -> path.join(path.dirname(p), path.basename(p, path.extname(p))) + ext
            
    #  0000000   0000000   0000000
    # 000       000       000     
    # 000       0000000   0000000 
    # 000            000       000
    #  0000000  0000000   0000000 

    style: (selector, rule) ->
        for i in [0...document.styleSheets[0].cssRules.length]
            r = document.styleSheets[0].cssRules[i]
            if r?.selectorText == selector
                document.styleSheets[0].deleteRule i
        document.styleSheets[0].insertRule "#{selector} { #{rule} }", document.styleSheets[0].cssRules.length
    
    setStyle: (selector, key, value, ssid=0) ->
        for rule in document.styleSheets[ssid].cssRules
            if rule.selectorText == selector
                rule.style[key] = value
                return

    getStyle: (selector, key, value, ssid=0) ->
        for rule in document.styleSheets[ssid].cssRules
            if rule.selectorText == selector
                return rule.style[key]
        return value
                
    # 0000000     0000000   00     00
    # 000   000  000   000  000   000
    # 000   000  000   000  000000000
    # 000   000  000   000  000 0 000
    # 0000000     0000000   000   000
        
    $: (idOrClass, e=document) -> 
        if idOrClass[0] in ['.', "#"] or e != document
            e.querySelector idOrClass
        else
            document.getElementById idOrClass

    absPos: (event) ->
        event = if event? then event else window.event
        if isNaN window.scrollX
            return pos(event.clientX + document.documentElement.scrollLeft + document.body.scrollLeft,
                       event.clientY + document.documentElement.scrollTop + document.body.scrollTop)
        else
            return pos(event.clientX + window.scrollX, event.clientY + window.scrollY)

    childIndex: (e) -> Array.prototype.indexOf.call(e.parentNode.childNodes, e)

    sw: () -> document.body.clientWidth
    sh: () -> document.body.clientHeight

#  0000000  000000000  00000000   000  000   000   0000000 
# 000          000     000   000  000  0000  000  000      
# 0000000      000     0000000    000  000 0 000  000  0000
#      000     000     000   000  000  000  0000  000   000
# 0000000      000     000   000  000  000   000   0000000 
    
if not String.prototype.splice
    String.prototype.splice = (start, delCount, newSubStr='') ->
        @slice(0, start) + newSubStr + @slice(start + Math.abs(delCount))
    String.prototype.strip = String.prototype.trim




