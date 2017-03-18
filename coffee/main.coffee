# 00     00   0000000   000  000   000
# 000   000  000   000  000  0000  000
# 000000000  000000000  000  000 0 000
# 000 0 000  000   000  000  000  0000
# 000   000  000   000  000  000   000

electron      = require 'electron'
noon          = require 'noon'
prefs         = require './tools/prefs'
about         = require './tools/about'
log           = require './tools/log'
pkg           = require '../package.json'
app           = electron.app
BrowserWindow = electron.BrowserWindow
Tray          = electron.Tray
Menu          = electron.Menu
clipboard     = electron.clipboard
ipc           = electron.ipcMain
win           = undefined
tray          = undefined

# 000  00000000    0000000
# 000  000   000  000     
# 000  00000000   000     
# 000  000        000     
# 000  000         0000000

ipc.on 'toggleMaximize', -> if win?.isMaximized() then win?.unmaximize() else win?.maximize()
ipc.on 'closeWin',       -> win?.close()
    
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
    log 'hello'
    cwd = __dirname
    win = new BrowserWindow
        backgroundColor: '#00000000'
        preloadWindow:   true
        resizable:       true
        center:          true
        transparent:     true
        alwaysOnTop:     true #!!!
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
    win.on 'ready-to-show', -> win.show(); win.webContents.send 'setWinID', win.id
    
    bounds = prefs.get 'bounds'
    win.setBounds bounds if bounds?
        
    win.on 'closed', -> win = null
    win.on 'close',  -> app.dock.hide()
    win.on 'blur',   onBlur
    win.on 'focus',  onFocus
    app.dock.show()
    win

onBlur = -> 
    log 'onBlur'
    win?.setIgnoreMouseEvents true
onFocus = -> 
    log 'onFocus'
    win?.setIgnoreMouseEvents false

saveBounds = ->
    if win?
        prefs.set 'bounds', win.getBounds()

showAbout = -> about img: "#{__dirname}/../img/about.png"
            
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
            role:        'hide'
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
            label:       'Bring All to Front'
            accelerator: 'Alt+Cmd+`'
            click:       -> win?.show()
        ,
            type: 'separator'
        ,   
            label:       'Reload Window'
            accelerator: 'Ctrl+Alt+Cmd+L'
            click:       -> win?.webContents.reloadIgnoringCache()
        ,                
            label:       'Toggle DevTools'
            accelerator: 'Cmd+Alt+I'
            click:       -> win?.webContents.openDevTools()
        ]
    ]
        
    prefs.init "#{app.getPath('userData')}/#{pkg.productName}.noon",
        shortcut: 'F6'

    electron.globalShortcut.register prefs.get('shortcut'), showWindow
    
    createWindow()

    