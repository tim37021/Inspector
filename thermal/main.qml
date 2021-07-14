import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.1
import QtGraphicalEffects 1.0
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
    color: appMaterial.background
    // title: `${spc.mouseCoordX}${spc.mouseCoordY}`
    AppStyle    { id: appStyle }
    AppMaterial { id: appMaterial }

    CsvLoader { 
        id: csv
    }

    PhaseWireCalc {
        id: c2cConv; 
        input: csv.output; 
        onCalcFinished: {
            channelUnits = csv.getChannelVUnits()
            let info = {
                "date": csv.getChannelDate(0),
                "time": csv.getChannelTime(0)
            }
            trn.setBaseInfo(info)
            // trn.calc()
        }
    }

    ThermalReportNode {
        id: trn
        input: c2cConv.output
        type: "BDEW"
    }

    ListModel { id: loadedSignals }

    FileDialog {
        id: ofd
        nameFilters: [ "csv files (*.csv)" ]
        onAccepted: {
            csv.filename = fileUrl
            csv.getHeader()
            wsw.open()
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
            // MenuItem { action: saveAsAction }
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
                id: gatherTracksView
                anchors.left: parent.left; anchors.right: parent.right;
                anchors.top: parent.top; anchors.bottom: lowerRulerArea.top;

                ListView {
                    id: gatherSignalView
                    anchors.fill: parent
                    model: gatherSignals
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
                color: appMaterial.surface2
                clip: false

                TrackRuler {
                    anchors.fill: parent
                    xValueAxis: xAxis_c2c
                    source: c2cConv.output
                }
            }

            ListModel { id: gatherSignals }

            Component {
                id: lowerTrack

                Rectangle {
                    id: gatherRect
                    anchors.left: parent.left; anchors.right: parent.right;
                    height: gatherTracksView.height
                    color: appMaterial.surface5

                    GatheredSignalTrack {
                        id: strack
                        source: c2cConv.output
                        anchors.fill: parent
                        model: loadedSignals
                        xValueAxis: xAxis_c2c
                        yValueAxis: yAxis_c2c
                        property int samplerate: 3000
                        property real displayDuration: 1

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
                        SectionIndicator {
                            id: sIndicate
                            anchors.fill: parent.plotSection
                            axisX: xAxis_c2c
                            borderColor: appMaterial.secondary
                            opacity: 0.8
                            onCoordinateMinChanged: {
                                updateDelay.restart()
                            }
                            onCoordinateMaxChanged: {
                                updateDelay.restart()
                            }
                            function updateReport() {
                                previewBox.topModel = [
                                    {"name": "No.", "v1": coordinateMin.toFixed(0), "v2": coordinateMax.toFixed(0), "v3": coordinateMax.toFixed(0) - coordinateMin.toFixed(0)}
                                ]
                                previewBox.bottomModel = c2cConv.getReport(coordinateMin.toFixed(0), coordinateMax.toFixed(0))
                                xAxis_.min = coordinateMin.toFixed(0)
                                xAxis_.max = coordinateMax.toFixed(0)
                            }

                            Timer {
                                id: updateDelay
                                interval: 200
                                repeat: false
                                triggeredOnStart: false
                                onTriggered: {
                                    sIndicate.updateReport();
                                }
                            }

                            Rectangle {
                                visible: sIndicate.hoverOnDrag
                                x: 10 + sIndicate.hoverMouseX
                                y: 10 + sIndicate.hoverMouseY
                                width: hoverText.width + 10
                                height: hoverText.height + 10
                                color: appMaterial.background
                                z: 100

                                Text {
                                    id: hoverText
                                    anchors.centerIn: parent
                                    text: sIndicate.hoverOnMinDrag? "t1:" + sIndicate.coordinateMin.toFixed(0): "t2:" + sIndicate.coordinateMax.toFixed(0)
                                    color: appMaterial.text
                                }
                            }
                        }
                    }
                    function signalFit() {
                        strack.signalFit()
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
            color: appMaterial.surface1

            Item {
                id: tracksView
                anchors.left: parent.left; anchors.right: parent.right;
                anchors.top: parent.top; anchors.bottom: rulerArea.top
                clip: true

                ListView {
                    id: tracksListView
                    anchors.fill: parent
                    model: loadedSignals
                    delegate: track
                    interactive: true
                    property int readyCount: 0
                    onModelChanged: readyCount = 0
                    onReadyCountChanged: {
                        if(readyCount == count){
                            csv.refresh()
                            delayUpdateTimer.restart()
                        }
                    }
                }

                Timer {
                    id: delayUpdateTimer
                    interval: 200
                    onTriggered: {
                        gatherSignalView.itemAtIndex(0).signalFit()
                        for(let i = 0; i<tracksListView.count; i++) {
                            tracksListView.itemAtIndex(i).signalFit()
                        }
                    }
                }

                Component {
                    id: track
                    Rectangle {
                        anchors.left: parent.left; anchors.right: parent.right;
                        height: lower.height * 0.12
                        color: appMaterial.surface6
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
                                tracksListView.readyCount += 1
                            }

                            function signalFit() {
                                xValueAxis.min = 0
                                xValueAxis.max = source.length
                                let yA = Math.max(
                                    Math.abs(source.getChannelMin(viewChannel)),
                                    Math.abs(source.getChannelMax(viewChannel))
                                )
                                yValueAxis.min =  - yA * 1.2
                                yValueAxis.max = yA * 1.2
                            }
                        }

                        function signalFit() {
                            strack.signalFit()
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
                color: appMaterial.surface2
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
        color: appMaterial.surface3
        property int minWidth: 300;

        MouseArea {
            anchors.top: parent.top; anchors.bottom: parent.bottom;
            anchors.left: parent.left;
            width: 10
            property real startX: 0.0
            cursorShape: Qt.SizeHorCursor
            enabled: rightView.width > 0

            onMouseXChanged: {
                rightView.width -=  mouseX - startX
                if(rightView.width < parent.minWidth)
                    rightView.width = parent.minWidth
            }
            onClicked: startX = mouseX
        }

        EstimatePreviewBox {
            id: previewBox
            anchors.fill: parent;
            anchors.margins: 10
        }
    }

    WireSettingWindow {
        id: wsw
        channelNames: c2cConv.channelName
        anchors.fill: parent
        // visible: false
        onAccepted: {
            csv.run()
            loadedSignals.clear()
            gatherSignals.clear()
            let colors = [
                'red',
                'blue',
                'green',
                'purple',
                'gray',
                'black',
                'yellow'
            ]
            let plotChannels = getSelectedChannel()
            for(let i = 0; i < plotChannels.length; i++) {
                loadedSignals.append({"plotChannel": plotChannels[i], "plotColor": colors[i % colors.length]})
            }
            gatherSignals.append({"plotChannel": 0, "plotColor": "red"})

            c2cConv.t1= 0
            c2cConv.t2= csv.output.length
            c2cConv.channels = channels
            c2cConv.inverse = inverses
        }
    }

    ReportSettingWindow {
        id: reportSetting
        anchors.fill: parent
        reporter: trn
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
        text: qsTr("&Export")
        shortcut: "Ctrl+S"
        onTriggered: {
            // sfd.open()
            reportSetting.open()
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
