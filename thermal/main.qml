
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.1
import App 1.0

// import hcmusic.audio 1.0
import hcmusic.plot 1.0
import hcmusic.dsp 1.0
import hcmusic.loader 1.0

import "components"

ApplicationWindow {
    id: app
    width: 800
    height: 600
    visible: true
    color: "black"
    // title: `${spc.mouseCoordX}${spc.mouseCoordY}`

    CsvLoader { 
        id: csv 
        onChannelsChanged: {
            loadedSignals.clear()
            let colors = [
                'red',
                'blue',
                'green',
                'purple',
                'gray',
                'black',
                'yellow'
            ]
            for(let i = 0; i < channels; i++) {
                loadedSignals.append({"plotChannel": i, "plotColor": colors[i]})
            }
        }
    }

    ListModel { id: loadedSignals }

    FileDialog {
        id: ofd
        nameFilters: [ "csv files (*.csv)" ]
        onAccepted: {
            csv.filename = fileUrl
        }
    }

    FileDialog {
        id: sfd
        nameFilters: [ "npz files (*.npz)" ]
        selectExisting: false
        onAccepted: {
            windowing.focusedWindow.signalSource.saveToFile(fileUrl)
        }
    }

    FileDialog {
        id: safd
        nameFilters: [ "npz files (*.npz)" ]
        selectExisting: false
        onAccepted: {
            windowing.focusedWindow.signalSource.saveToFile(fileUrl)
        }
    }

    menuBar: MenuBar {
        Menu {
            title: qsTr("&File")
            MenuItem { action: openAction }
            MenuItem { action: saveAction }
            MenuItem { action: saveAsAction }
            MenuSeparator { }
            Action { text: qsTr("&Quit") }
        }
        Menu {
            title: qsTr("&Edit")
            Action { text: qsTr("Cu&t") }
            Action { text: qsTr("&Copy") }
            Action { text: qsTr("&Paste") }
        }
        Menu {
            title: qsTr("&Help")
            Action { text: qsTr("&About") }
        }
    }

    Item {
        id: mainView
        anchors.top: parent.top; anchors.left: parent.left;
        anchors.bottom: parent.bottom; anchors.right: rightView.left;

        Item {
            id: upper
            anchors.left: parent.left; anchors.right: parent.right;
            anchors.top: parent.top; anchors.bottom: lower.top;

            Item {
                id: tracksView
                anchors.left: parent.left; anchors.right: parent.right;
                anchors.top: parent.top; anchors.bottom: rulerArea.top

                ListView {
                    anchors.fill: parent
                    model: loadedSignals
                    delegate: track
                    // snapMode: ListView.SnapToItem
                    interactive: loadedSignals.length > 6
                }
            }
            
            // Rectangle {
            //     id: ruler
            //     anchors.left: parent.left; anchors.right: parent.right;
            //     anchors.bottom: parent.bottom
            //     height: 60
            //     color: "yellow"
            // }

            Rectangle {
                id:rulerArea
                anchors.left: parent.left; anchors.right: parent.right;
                anchors.bottom: parent.bottom
                anchors.leftMargin: tracksView.width * 0.15
                height: 30
                color: "gray"
                clip: true

                ListView {
                    id: ruler
                    anchors.fill: parent
                    
                    orientation: ListView.Horizontal
                    model: (csv.output.length / 3000).toFixed(0)
                    contentX: (xAxis_.min / (3000 * 5)) * ruler.width
                    interactive: false
                    delegate: Item {
                        width: ruler.width * 3000 / (xAxis_.max - xAxis_.min )
                        height: ruler.height
                        Rectangle {
                            width: 1
                            height: 10
                            anchors.left: parent.left
                            anchors.top: parent.top
                        }
                        Text {
                            text: index
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            color: "white"
                        }
                    }
                }
            }

            ValueAxis {
                id: xAxis_
                min: 0
                max: 1000
                onMinChanged: {
                    if(min <=  0) min = 0
                }
                onMaxChanged: {
                    if(max >= csv.output.length) max = csv.output.length
                }
            }

            ValueAxis {
                id: yAxis_
                min: 0
                max: 0
            }

            Component {
                id: track

                Rectangle {
                    anchors.left: parent.left; anchors.right: parent.right;
                    height: upper.height * 0.15
                    SignalTrack {
                        id: strack
                        source: csv.output
                        viewChannel: plotChannel
                        lineColor: plotColor
                        anchors.fill: parent
                        xValueAxis: xAxis_
                        yValueAxis: yAxis_

                        Component.onCompleted: {
                            csv.refresh()
                            this.signalFit()
                        }
                    }
                }
            }
        }

        Rectangle {
            id: lower
            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right;
            height: parent.height * 0.3
            color: "blue"

            // GatheredSignalTrack {
            //     id: gatherTrack
            //     visible: loadedSignals.count > 0
            //     anchors.fill: parent
            //     input: csv.output
            //     xValueAxis: xAxis_
            //     yValueAxis: yAxis_

            //     Component.onCompleted: {
            //         console.log(csv.output.getChannelMax(0))
            //     }
            // }

            MouseArea {
                anchors.top: parent.top; anchors.right: parent.right;
                anchors.left: parent.left;
                height: 10
                property real startY: 0.0
                cursorShape: Qt.SizeVerCursor
                enabled: lower.width > 0

                onMouseYChanged: {
                    lower.height -=  mouseY - startY
                    if(lower.height < 10)
                        lower.height = 10
                }
                onClicked: startY = mouseY
            }
        }
    }

    Rectangle {
        id: rightView
        anchors.top: parent.top; anchors.bottom: parent.bottom;
        anchors.right: parent.right; 
        width: app.width * 0.3
        color: "green"

        MouseArea {
            anchors.top: parent.top; anchors.bottom: parent.bottom;
            anchors.left: parent.left;
            width: 10
            property real startX: 0.0
            cursorShape: Qt.SizeHorCursor
            enabled: rightView.width > 0

            onMouseXChanged: {
                rightView.width -=  mouseX - startX
                if(rightView.width < 10)
                    rightView.width = 10
            }
            onClicked: startX = mouseX
        }
    }

    // Actions 
    Action { 
        id: openAction
        text: qsTr("&Open")
        shortcut: "Ctrl+O"
        onTriggered: {
            ofd.open()
        }
    }

    Action { 
        id: saveAction
        text: qsTr("&Save")
        shortcut: "Ctrl+S"
        onTriggered: {
            sfd.open()
        }
    }
    Action { 
        id: saveAsAction
        text: qsTr("Save &As")
        shortcut: "Ctrl+Shift+S"
        onTriggered: {
            safd.open()
        }
    }
}
