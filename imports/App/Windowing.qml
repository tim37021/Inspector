import QtQuick 2.12

Item {
    property SubWindow focusedWindow: null
    
    anchors.fill: parent

    function createWindow(template, data) {
        if(data == undefined)
            data = {}
        let newwin = template.createObject(this, data)
        moveToTop(newwin)
        return newwin
    }

    function moveToTop(window) {
        if(focusedWindow)
            focusedWindow.z = 0
        focusedWindow = window
        focusedWindow.z = 10
    }

}