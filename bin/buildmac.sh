#!/usr/bin/env bash

DIR=`dirname $0`
BIN=$DIR/../node_modules/.bin
cd $DIR/..

if rm -rf ruler-darwin-x64; then

    if $BIN/konrad; then
    
        $BIN/electron-rebuild
    
        IGNORE="/(.*\.dmg$|Icon$|coffee$|.*md$|pug$|styl$|.*\.lock$|img/banner\.png)"
        
        if $BIN/electron-packager . --overwrite --icon=img/app.icns --darwinDarkModeSupport --ignore=$IGNORE; then
        
            rm -rf /Applications/ruler.app
            cp -R ruler-darwin-x64/ruler.app /Applications
            
            open /Applications/ruler.app 
        fi
    fi
fi