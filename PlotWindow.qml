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

        property Algorithm algo: Algorithm {
            onIncomming: {
                console.log(target.get(lv.currentIndex).addr)
            }
        }


        onTriggered: {
            if(lv.currentIndex >= 0) {
                let reading = target.get(lv.currentIndex).rssi                
                let freading = ls.filter.f(reading)
                ls.append(freading)
                ls2.append(reading)

                algo.feed(freading)

                // move mouse cursor
                //if(ctl.mouseCoordX >= 0 && ctl.mouseCoordX < ls.length)
                //    ui.set(0, {px: ctl.mouseCoordX, py: ls.array[Math.ceil(ctl.mouseCoordX)]})
            }
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
            
            length: 4096
        }

        LineSeries {
            id: ls2
            xAxis: xAxis_
            yAxis: yAxis_

            color: "green"

            lineWidth: 2
            
            length: 4096
        }

        Keys.onPressed: {
            app.createQuickPlotWindow('plot', null)
        }

    }

    ListView {
        id: lv
        anchors.bottom: parent.bottom
        x: parent.width * 0.1
        width: parent.width * 0.8
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
                        } else
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
