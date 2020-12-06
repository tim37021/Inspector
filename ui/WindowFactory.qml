import QtQuick 2.12

QtObject {
    property Component quickplot: QuickPlotWindow {
        width: app.width * 0.8
        height: app.height * 0.8
    }

    property Component image: ImageWindow {
        width: app.width * 0.8
        height: app.height * 0.8
    }

    property var windows: {
            'quickplot': quickplot,
            'image': image
        }

    function fetch(name) {
        return windows[name]
    }
    
}
