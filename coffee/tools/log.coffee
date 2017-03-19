#000       0000000    0000000 
#000      000   000  000      
#000      000   000  000  0000
#000      000   000  000   000
#0000000   0000000    0000000 

str  = require './str'

log = -> 
    t = (str(s) for s in [].slice.call arguments, 0).join " "
    console.log t
    if document?
        document.getElementById("area").innerHTML += t+'<br>'

module.exports = log