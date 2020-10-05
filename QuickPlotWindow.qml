import QtQuick 2.12
import App 1.0
import hcmusic.plot 1.0

SubWindow {

    property var signalSource

    onSignalSourceChanged: {
        if(signalSource && signalSource.array)
            ls.set(signalSource.array)
        if(signalSource && Array.isArray(signalSource))
            ls.set(signalSource)
        
    }

    Connections {
        target: signalSource instanceof QtObject? signalSource: null

        function onUpdate(array) {
            ls.set(array)
        }
    }

    Rectangle {
        y: 24
        width: parent.width * 0.8 + 16
        height: parent.height * 0.8 + 16
        anchors.centerIn: parent
        color: "transparent"

        radius: 8

        border.color: "white"
        border.width: 1
    }

    InteractivePlot {
        y: 24
        width: parent.width * 0.8
        height: parent.height * 0.8
        anchors.centerIn: parent
        mouseAnchor.visible: false

        xAxis: ValueAxis {
            id: xAxis_
            min: 0
            max: 4096
        }

        yAxis: ValueAxis {
            id: yAxis_
            min: -80
            max: 80
        }

        LineSeries {
            id: ls
            xAxis: xAxis_
            yAxis: yAxis_
            color: Qt.rgba(247/255, 193/255, 121/255, 1.0)
            length: 2
        }

    }
}