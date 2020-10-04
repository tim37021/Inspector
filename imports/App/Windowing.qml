import QtQuick 2.12

Item {
    property SubWindow focusedWindow: null

    function createWindow(template, data) {
        if(data == undefined)
            data = {}
        return template.createObject(this, data)
    }

    function moveToTop(window) {
        if(focusedWindow)
            focusedWindow.z = 0
        focusedWindow = window
        focusedWindow.z = 10
    }

}