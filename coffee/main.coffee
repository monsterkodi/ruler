# 00     00   0000000   000  000   000
# 000   000  000   000  000  0000  000
# 000000000  000000000  000  000 0 000
# 000 0 000  000   000  000  000  0000
# 000   000  000   000  000  000   000
{
resolve,
prefs,
about,
log
}             = require 'kxk'
pkg           = require '../package.json'
childp        = require 'child_process'
electron      = require 'electron'
noon          = require 'noon'
app           = electron.app
BrowserWindow = electron.BrowserWindow
nativeImage   = electron.nativeImage
Tray          = electron.Tray
Menu          = electron.Menu
clipboard     = electron.clipboard
ipc           = electron.ipcMain
win           = null
tray          = null
scheme        = 'dark'

# 000  00000000    0000000
# 000  000   000  000     
# 000  00000000   000     
# 000  000        000     
# 000  000         0000000

ipc.on 'toggleMaximize', -> if win?.isMaximized() then win?.unmaximize() else win?.maximize()
ipc.on 'closeWin',       -> win?.close()
ipc.on 'setScheme', (event, arg) -> scheme = arg
ipc.on 'copyImage', (event, arg) -> copyImage arg
    
#000   000  000  000   000  0000000     0000000   000   000
#000 0 000  000  0000  000  000   000  000   000  000 0 000
#000000000  000  000 0 000  000   000  000   000  000000000
#000   000  000  000  0000  000   000  000   000  000   000
#00     00  000  000   000  0000000     0000000   00     00

toggleWindow = ->
    if win?.isVisible()
        win.hide()    
        app.dock.hide()
    else
        showWindow()

showWindow = ->
    if win?
        win.show()
    else
        createWindow()
    app.dock.show()
    
createWindow = ->
    cwd = __dirname
    win = new BrowserWindow
        backgroundColor: '#00000000'
        preloadWindow:   true
        resizable:       true
        center:          true
        transparent:     true
        alwaysOnTop:     true
        frame:           false
        show:            false
        fullscreenable:  false
        hasShadow:       false
        minimizable:     false
        maximizable:     false
        width:           1000
        height:          1000
        minWidth:        22
        minHeight:       22
        
    win.loadURL "file://#{cwd}/ruler.html"
    win.on 'ready-to-show', -> win.show()
    
    bounds = prefs.get 'bounds'
    win.setBounds bounds if bounds?
        
    win.on 'closed', -> win = null
    win.on 'close',  -> app.dock.hide()
    win.on 'move',   saveBounds
    win.on 'resize', saveBounds
    win.on 'blur',   onBlur
    win.on 'focus',  onFocus
    app.dock.show()
    win

onBlur = -> 
    win?.setIgnoreMouseEvents true
    win?.webContents.send 'setActive', false
onFocus = -> 
    win?.setIgnoreMouseEvents false
    win?.webContents.send 'setActive', true

saveBounds = -> if win? then prefs.set 'bounds', win.getBounds()

showAbout = -> 
    about 
        img: "#{__dirname}/../img/about.png"
        background: scheme == 'bright' and '#fff' or "#222"
        size: 300
        pkg: pkg

#  0000000   0000000   00000000   000   000  000  00     00   0000000    0000000   00000000  
# 000       000   000  000   000   000 000   000  000   000  000   000  000        000       
# 000       000   000  00000000     00000    000  000000000  000000000  000  0000  0000000   
# 000       000   000  000           000     000  000 0 000  000   000  000   000  000       
#  0000000   0000000   000           000     000  000   000  000   000   0000000   00000000  

copyImage = (rect) ->
    tmpFile = resolve '$TMPDIR/ruler.png'
    rect.x += win.getBounds().x
    rect.y += win.getBounds().y
    win.hide()
    childp.exec "screencapture -T 0 \"#{tmpFile}\"", (err) -> 
        win.show()
        if err? then log "[ERROR] screencapture: #{err}"
        img = nativeImage.createFromPath tmpFile
        rect.x *= 2
        rect.y *= 2
        rect.width *= 2
        rect.height *= 2
        img = img.crop rect
        clipboard.writeImage img
            
app.on 'window-all-closed', (event) -> event.preventDefault()

#00000000   00000000   0000000   0000000    000   000
#000   000  000       000   000  000   000   000 000 
#0000000    0000000   000000000  000   000    00000  
#000   000  000       000   000  000   000     000   
#000   000  00000000  000   000  0000000       000   

app.on 'ready', -> 
    
    tray = new Tray "#{__dirname}/../img/menu.png"
    tray.on 'click', toggleWindow
    app.dock.hide() if app.dock
            
    # 00     00  00000000  000   000  000   000
    # 000   000  000       0000  000  000   000
    # 000000000  0000000   000 0 000  000   000
    # 000 0 000  000       000  0000  000   000
    # 000   000  00000000  000   000   0000000 
    
    Menu.setApplicationMenu Menu.buildFromTemplate [
        label: app.getName()
        submenu: [
            label: "About #{pkg.name}"
            accelerator: 'Cmd+.'
            click: -> showAbout()
        ,            
            type: 'separator'
        ,
            label:       "Hide #{pkg.productName}"
            accelerator: 'Cmd+H'
            click:        -> win?.close()
        ,
            label:       'Hide Others'
            accelerator: 'Cmd+Alt+H'
            role:        'hideothers'
        ,
            type: 'separator'
        ,
            label:        'Quit'
            accelerator: 'Command+Q'
            click: -> 
                saveBounds()
                app.exit 0
        ]
    ,
        # 000   000  000  000   000  0000000     0000000   000   000
        # 000 0 000  000  0000  000  000   000  000   000  000 0 000
        # 000000000  000  000 0 000  000   000  000   000  000000000
        # 000   000  000  000  0000  000   000  000   000  000   000
        # 00     00  000  000   000  0000000     0000000   00     00
        
        label: 'Window'
        submenu: [
            label:       'Minimize'
            accelerator: 'Alt+Cmd+M'
            click:       -> win?.minimize()
        ,
            label:       'Maximize'
            accelerator: 'Cmd+Shift+m'
            click:       -> if win?.isMaximized() then win?.unmaximize() else win?.maximize()
        ,
            type: 'separator'
        ,                            
            label:       'Close Window'
            accelerator: 'Cmd+W'
            click:       -> win?.close()
        ,
            type: 'separator'
        ,                
            label:       'Toggle DevTools'
            accelerator: 'Cmd+Alt+I'
            click:       -> win?.webContents.openDevTools()
        ]
    ]
        
    prefs.init shortcut: 'F3', capture: 'command+F3'

    electron.globalShortcut.register prefs.get('shortcut'), toggleWindow
    electron.globalShortcut.register prefs.get('capture'),  -> win?.webContents.send 'capture'
    
    createWindow()

    