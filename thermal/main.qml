import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.1
import App 1.0

import Qt.labs.qmlmodels 1.0

// import hcmusic.audio 1.0
import hcmusic.plot 1.0
import hcmusic.dsp 1.0
import hcmusic.loader 1.0

import "components"

ApplicationWindow {
    id: app
    width: 1280
    height: 960
    visible: true
    color: "black"
    // title: `${spc.mouseCoordX}${spc.mouseCoordY}`
    AppStyle { id: appStyle }

    CsvLoader { 
        id: csv
        onChannelsChanged: {
            loadedSignals.clear()
            lowerLoadedSignals.clear()
            let colors = [
                'red',
                'blue',
                'green',
                'purple',
                'gray',
                'black',
                'yellow'
            ]
            let plotChannels = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
            for(let i = 0; i < plotChannels.length; i++) {
                loadedSignals.append({"plotChannel": plotChannels[i], "plotColor": colors[i % colors.length]})
            }
            lowerLoadedSignals.append({"plotChannel": 0, "plotColor": "red"})
        }
    }

    PhaseWireCalc { id: c2cConv; input: csv.output; t1:0; t2: input.length; channels: [0, 1, 2, 3, 4, 5]//[0, 1, 2, 4, 5, 3]
        onCalcFinished: {
            channelUnits = csv.getChannelVUnits()
            itTop.model = [
                {"name": "No.", "v1": "1", "v2": "10001", "v3": "10000"}
            ]
            itLow.model = this.getReport(0, 10000)
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
                id: lowerTracksView
                anchors.left: parent.left; anchors.right: parent.right;
                anchors.top: parent.top; anchors.bottom: lowerRulerArea.top;

                ListView {
                    anchors.fill: parent
                    model: lowerLoadedSignals
                    delegate: lowerTrack
                    interactive: loadedSignals.length > 6
                }
            }

            Rectangle {
                id:lowerRulerArea
                anchors.left: parent.left; anchors.right: parent.right;
                anchors.bottom: parent.bottom
                anchors.leftMargin: Math.min(tracksView.width * 0.15, 80)
                height: 20
                color: appStyle.ruler
                clip: true

                TrackRuler {
                    anchors.fill: parent
                    xValueAxis: xAxis_c2c
                    source: c2cConv.output
                }
            }

            ListModel { id: lowerLoadedSignals }

            Component {
                id: lowerTrack

                Rectangle {
                    anchors.left: parent.left; anchors.right: parent.right;
                    height: lowerTracksView.height

                    GatheredSignalTrack {
                        id: strack
                        source: c2cConv.output
                        anchors.fill: parent
                        model: loadedSignals
                        xValueAxis: xAxis_c2c
                        yValueAxis: yAxis_c2c
                        property int samplerate: 3000
                        property real displayDuration: 1
                        
                        onPlotReady: {
                            csv.refresh()
                            this.signalFit()
                        }

                        function signalFit() {
                            xValueAxis.min = 0
                            xValueAxis.max = source.length // max for 5 seconds
                            let yA = Math.max(
                                Math.abs(source.getChannelMin(0)),
                                Math.abs(source.getChannelMax(0))
                            )
                            if(yValueAxis.min > ( - yA - 10))
                                yValueAxis.min =  - yA - 10

                            if(yValueAxis.max < (yA + 10))
                                yValueAxis.max = yA + 10
                        }
                    }
                }
            }

            ValueAxis {
                id: xAxis_c2c
                min: 0
                max: c2cConv.output.length

                onMinChanged: {
                    if(min <=  0) min = 0
                }
                onMaxChanged: {
                    if(max >= c2cConv.output.length) max = c2cConv.output.length
                }
            }

            ValueAxis { id: yAxis_c2c; min: 0; max: 0 }

        }

        Rectangle {
            id: lower
            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right;
            height: parent.height * 0.8
            color: appStyle.lowerSection

            Item {
                id: tracksView
                anchors.left: parent.left; anchors.right: parent.right;
                anchors.top: parent.top; anchors.bottom: rulerArea.top

                ListView {
                    anchors.fill: parent
                    model: loadedSignals
                    delegate: track
                    interactive: false
                }

                Component {
                    id: track

                    Rectangle {
                        anchors.left: parent.left; anchors.right: parent.right;
                        height: lower.height * 0.12
                        ValueAxis {
                            id: yTrackComp_
                        }
                        SignalTrack {
                            id: strack
                            source: c2cConv.output
                            infoText: c2cConv.channelName[plotChannel]
                            viewChannel: plotChannel
                            lineColor: plotColor
                            anchors.fill: parent
                            xValueAxis: xAxis_
                            yValueAxis: yTrackComp_
                            property int displayDuration: 1
                            property int samplerate: 10000

                            onPlotReady: {
                                csv.refresh()
                                this.signalFit()
                            }

                            function signalFit() {
                                xValueAxis.min = 0
                                // xValueAxis.max = samplerate * displayDuration // max for 5 seconds
                                xValueAxis.max = source.length
                                let yA = Math.max(
                                    Math.abs(source.getChannelMin(viewChannel)),
                                    Math.abs(source.getChannelMax(viewChannel))
                                )
                                if(yValueAxis.min > ( - yA - 10))
                                    yValueAxis.min =  - yA - 10

                                if(yValueAxis.max < (yA + 10))
                                    yValueAxis.max = yA + 10
                            }
                        }
                    }
                }
            }

            Rectangle {
                id:rulerArea
                anchors.left: parent.left; anchors.right: parent.right;
                anchors.bottom: parent.bottom
                anchors.leftMargin: Math.min(tracksView.width * 0.15, 80)
                height: 30
                color: appStyle.ruler
                clip: true

                TrackRuler {
                    anchors.fill: parent
                    xValueAxis: xAxis_
                    source: csv.output
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
        color: appStyle.rightSection

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

        Item {
            anchors.fill: parent;
            anchors.margins: 10

            Item {
                id: itTopArea
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right;
                // anchors.margins: 10
                height: 60

                InfoTable2 {
                    id: itTop
                    anchors.fill: parent
                    headerNames: ["", "Cursor1", "Cursor2", "CursorDiff"]
                }
            }

            Item {
                id: itBottomArea
                anchors.top: itTopArea.bottom; anchors.bottom: parent.bottom; 
                anchors.left: parent.left; anchors.right: parent.right;

                InfoTable2 {
                    id: itLow
                    anchors.fill: parent
                }
            }        
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
