import QtQuick 2.12

QtObject {

    property Component plot: PlotWindow {
        width: app.width * 0.8
        height: app.height * 0.8
    }
    
    property Component quickplot: QuickPlotWindow {
        width: app.width * 0.8
        height: app.height * 0.8
    }

    property Component race: RaceWindow {
        x: app.width - width - 16
        y: app.height - height - 16
        width: app.width * 0.4
        height: app.height * 0.3   
    }

    property Component image: ImageWindow {
        width: app.width * 0.8
        height: app.height * 0.8
    }

    property var windows: {
            'plot': plot,
            'quickplot': quickplot,
            'race': race,
            'image': image
        }

    function fetch(name) {
        return windows[name]
    }
    
}