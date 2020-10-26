import QtQuick 2.12
import QtQuick.Controls 2.12

// SubWindow
import App 1.0
import hcmusic.plot 1.0
import nrf.beacon 1.0

SubWindow {
    id: root
    //color: "#212c70"
    property TrackedDeviceModel target

    Timer {
        running: true
        interval: 50
        repeat: true


        onTriggered: {
            
            if(target && target.count) {
                let reading = target.get(lv.currentIndex).rssi                
                let freading = ls.filter.f(reading)
                ls.append(freading)
                ls2.append(reading)
            }
            // move mouse cursor
            if(plot.mouseCoordX >= 0 && plot.mouseCoordX < ls.length) {
                plot.mouseAnchor.px = plot.mouseCoordX
                plot.mouseAnchor.py = ls.array[Math.ceil(plot.mouseCoordX)]
            }
            
        }
    }
   

    Rectangle {
        y: 24
        width: plot.width + 16
        height: plot.height + 16
        anchors.centerIn: parent
        color: "transparent"

        radius: 8

        border.color: "white"
        border.width: 1
    }

    InteractivePlot {
        id: plot
        y: 24
        width: parent.width * 0.9
        height: parent.height * 0.8
        anchors.centerIn: parent

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
            property RSSIFilter filter: RSSIFilter {}

            color: Qt.rgba(247/255, 193/255, 121/255, 1.0)

            lineWidth: 2
            visible: lv.currentIndex !== -1
            
            length: 4096
        }

        LineSeries {
            id: ls2
            xAxis: xAxis_
            yAxis: yAxis_

            color: "green"

            lineWidth: 2
            visible: lv.currentIndex !== -1
            
            length: 4096
        }
    }


    ListView {
        id: lv
        anchors.bottom: parent.bottom
        anchors.left: plot.left
        
        width: plot.width
        height: parent.height * 0.1
        orientation: ListView.Horizontal

        model: target

        delegate: Item {
            width: 128
            height: lv.height
            clip: true

            Row {
                spacing: 10
                anchors.fill: parent
                Rectangle {
                    radius: 8
                    width: 16
                    height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: {
                        
                        if(lv.currentIndex === model.index) {
                            return "green"
                        } else if(!model.active)
                            return "black"
                        else
                            return "gray"
                    }
                }
                Text {
                    text: model.addr
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: lv.currentIndex = model.index
            } 

        }

        onCurrentIndexChanged: {
            ls.init()
            ls2.init()
            ls.filter.init()
        }
    }

}
