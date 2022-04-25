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
    width: 1920
    height: 1080
    visible: true
    color: appMaterial.background
    // title: `${spc.mouseCoordX}${spc.mouseCoordY}`
    AppStyle    { id: appStyle }
    AppMaterial { id: appMaterial }

    // Data
    ListModel { id: loadedSignals }
    ListModel { id: gatherSignals }

    FileDialog {
        id: ofd
        nameFilters: [ "csv files (*.csv)" ]
        onAccepted: {
            ProcessManager.csv.filename = fileUrl
            ProcessManager.csv.getHeader()
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
            anchors.top: parent.top; anchors.bottom: middle.top;

            Item {
                id: gatherTracksView
                anchors.left: parent.left; anchors.right: parent.right;
                anchors.top: parent.top; anchors.bottom: lowerRulerArea.top;
                
                ListView {
                    id: gatherSignalView
                    anchors.fill: parent
                    model: ProcessManager.gatherModel
                    delegate: gatherTrack
                    interactive: false
                }

                ZoomIndicator {
                    id: zIndicate
                    visible: ProcessManager.gatherModel.count > 0
                    anchors.fill: parent
                    anchors.leftMargin: Math.min(parent.width * 0.15, 80)
                    axisX: xAxis_c2c
                    borderColor: appMaterial.secondary
                    opacity: 0.8
                    onCoordinateMinChanged: {
                        xAxis_.min = parseFloat(coordinateMin.toFixed(0))
                        xAxis_.max = parseFloat(coordinateMax.toFixed(0))
                        // if(!(hoverOnDrag || zIndicate.hoverOnDrag)) return
                        if(ProcessManager.sectionAxis.min !== parseFloat(sIndicate.coordinateMin.toFixed(0)))
                            ProcessManager.sectionAxis.min = parseFloat(sIndicate.coordinateMin.toFixed(0))
                        if(ProcessManager.sectionAxis.max !== parseFloat(sIndicate.coordinateMax.toFixed(0)))
                            ProcessManager.sectionAxis.max = parseFloat(sIndicate.coordinateMax.toFixed(0))
                        lsIndicate.setStartTime(ProcessManager.sectionAxis.min)
                        lsIndicate.setEndTime(ProcessManager.sectionAxis.max)
                    }
                    onCoordinateMaxChanged: {
                        xAxis_.min = parseFloat(coordinateMin.toFixed(0))
                        xAxis_.max = parseFloat(coordinateMax.toFixed(0))
                        // if(!(hoverOnDrag || zIndicate.hoverOnDrag)) return
                        if(ProcessManager.sectionAxis.min !== parseFloat(sIndicate.coordinateMin.toFixed(0)))
                            ProcessManager.sectionAxis.min = parseFloat(sIndicate.coordinateMin.toFixed(0))
                        if(ProcessManager.sectionAxis.max !== parseFloat(sIndicate.coordinateMax.toFixed(0)))
                            ProcessManager.sectionAxis.max = parseFloat(sIndicate.coordinateMax.toFixed(0))
                        lsIndicate.setStartTime(ProcessManager.sectionAxis.min)
                        lsIndicate.setEndTime(ProcessManager.sectionAxis.max)
                    }

                    Rectangle {
                        visible: zIndicate.hoverOnDrag
                        x: 10 + zIndicate.hoverMouseX
                        y: 10 + zIndicate.hoverMouseY
                        width: hoverText.width + 10
                        height: hoverText.height + 10
                        color: appMaterial.background
                        z: 100

                        Text {
                            id: hoverText
                            anchors.centerIn: parent
                            text: zIndicate.hoverOnMinDrag? "t1:" + zIndicate.coordinateMin.toFixed(0).toString(): "t2:" + zIndicate.coordinateMax.toFixed(0).toString()
                            color: appMaterial.text
                        }
                    }
                }

                SectionIndicator {
                    id: sIndicate
                    visible: ProcessManager.gatherModel.count > 0
                    anchors.fill: parent
                    anchors.leftMargin: Math.min(parent.width * 0.15, 80)
                    axisX: xAxis_c2c
                    onCoordinateMinChanged: {
                        if(!(hoverOnDrag || zIndicate.hoverOnDrag)) return
                        if(ProcessManager.sectionAxis.min !== parseFloat(coordinateMin.toFixed(0)))
                            ProcessManager.sectionAxis.min = parseFloat(coordinateMin.toFixed(0))
                        lsIndicate.setStartTime(ProcessManager.sectionAxis.min)
                    }
                    onCoordinateMaxChanged: {
                        if(!(hoverOnDrag || zIndicate.hoverOnDrag)) return
                        if(ProcessManager.sectionAxis.max !== parseFloat(coordinateMax.toFixed(0)))
                            ProcessManager.sectionAxis.max = parseFloat(coordinateMax.toFixed(0))
                        lsIndicate.setEndTime(ProcessManager.sectionAxis.max)
                    }
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
            }

            Component {
                id: gatherTrack

                Rectangle {
                    id: gatherRect
                    property alias plotSection: strack.plotSection
                    // anchors.left: parent.left; anchors.right: parent.right;
                    width: gatherTracksView.width
                    height: gatherTracksView.height
                    color: appMaterial.surface5

                    GatheredSignalTrack {
                        id: strack
                        source: ProcessManager.c2cConv.output
                        anchors.fill: parent
                        model: gatherSignals
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
                        
                    }
                    function signalFit() {
                        strack.signalFit()
                    }
                    
                }
            }

            ValueAxis {
                id: xAxis_c2c
                min: 0
                max: ProcessManager.c2cConv.output.length

                onMinChanged: {
                    if(min <=  0) min = 0
                }
                onMaxChanged: {
                    if(max >= ProcessManager.c2cConv.output.length) max = ProcessManager.c2cConv.output.length
                }
            }

            ValueAxis { id: yAxis_c2c; min: 0; max: 0 }

        }

        Rectangle {
            id: middle
            anchors.bottom: lower.top; anchors.left: parent.left; anchors.right: parent.right;
            height: 40
            color: appMaterial.surface3

            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                spacing: 10

                BaseIconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    iconType: AppIcon.Center
                    backgroundColor: appMaterial.surface6
                    hoverColor: appMaterial.surface2
                    pressedColor: appMaterial.errorOn

                    onClicked: {
                        centerSignal.trigger()
                    }
                }

                BaseIconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    iconType: AppIcon.ZoomIn
                    backgroundColor: appMaterial.surface6
                    hoverColor: appMaterial.surface2
                    pressedColor: appMaterial.errorOn

                    onClicked: {
                        zoomIn.trigger()
                    }
                }

                BaseIconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    iconType: AppIcon.ZoomOut
                    backgroundColor: appMaterial.surface6
                    hoverColor: appMaterial.surface2
                    pressedColor: appMaterial.errorOn

                    onClicked: {
                        zoomOut.trigger()
                    }
                }
            }
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
                    delegate: Rectangle {
                        // anchors.left: tracksView.left; anchors.right: tracksView.right;
                        width: tracksView.width
                        height: lower.height * 0.12
                        color: appMaterial.surface6
                        ValueAxis {
                            id: yTrackComp_
                        }
                        ListModel {
                            id: trackSignalModel
                        }
                        GatheredSignalTrack {
                            id: strack
                            source: ProcessManager.c2cConv.output
                            // infoText: ProcessManager.c2cConv.channelName[plotChannel]
                            infoText: {
                                let ret = ""
                                let dict = JSON.parse(JSON.stringify(tracksListView.model.get(index)))

                                for (var key in dict) {
                                    trackSignalModel.append(dict[key])
                                    let channelName = ProcessManager.c2cConv.channelName[dict[key]["plotChannel"]]
                                    ret = ret + channelName + " "
                                }
                                return ret
                            }
                            model: {
                                trackSignalModel.clear()
                                let dict = JSON.parse(JSON.stringify(tracksListView.model.get(index)))
                                let ret = []

                                for (var key in dict) {
                                    trackSignalModel.append(dict[key])
                                    ret.push(dict[key])
                                }
                                return trackSignalModel
                            }
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

                                let minValue = source.getChannelMin(trackSignalModel.get(0)["plotChannel"])
                                let maxValue = source.getChannelMax(trackSignalModel.get(0)["plotChannel"])
                                let delta = maxValue - minValue

                                yValueAxis.min = minValue - delta / 6 * 2
                                yValueAxis.max = maxValue + delta / 6 * 2
                            }
                        }

                        function signalFit() {
                            strack.signalFit()
                        }
                    }
                    interactive: true
                    property int readyCount: 0
                    ScrollBar.vertical: ScrollBar { }
                    onModelChanged: {
                        readyCount = 0
                    }
                    
                    onReadyCountChanged: {
                        if(readyCount == count && count != 0){
                            app.refreshPlot()
                        }
                    }
                }

                Item {
                    visible: loadedSignals.count > 0
                    anchors.fill: parent
                    anchors.leftMargin: Math.min(parent.width * 0.15, 80)
                    clip: true

                    SectionIndicator {
                        id: lsIndicate
                        anchors.fill: parent
                        axisX: xAxis_
                        textColor: "white"
                        onCoordinateMinChanged: {
                            if(!hoverOnDrag) return
                            if(ProcessManager.sectionAxis.min !== parseFloat(coordinateMin.toFixed(0)))
                                ProcessManager.sectionAxis.min = parseFloat(coordinateMin.toFixed(0))
                            sIndicate.setStartTime(ProcessManager.sectionAxis.min)
                        }
                        onCoordinateMaxChanged: {
                            if(!hoverOnDrag) return
                            if(ProcessManager.sectionAxis.max !== parseFloat(coordinateMax.toFixed(0)))
                                ProcessManager.sectionAxis.max = parseFloat(coordinateMax.toFixed(0))
                            sIndicate.setEndTime(ProcessManager.sectionAxis.max)
                        }
                    }
                }

                

                Timer {
                    id: delayUpdateTimer
                    interval: 1000
                    onTriggered: {
                        centerSignal.trigger()
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

                AxisRuler {
                    id: lowerRuler
                    anchors.fill: parent
                    axis: xAxis_
                    stride: Math.pow(10, getDigit(axis.max - axis.min) - 1)
                    visible: tracksListView.model.count > 0

                    function getDigit(value) {
                        return value.toString().length
                    }
                }
            }

            ValueAxis {
                id: xAxis_
                min: 0
                max: 300300
                onMinChanged: {
                    if(min <=  0) min = 0
                }
                onMaxChanged: {
                    if(max >= ProcessManager.c2cConv.output.length) max = ProcessManager.c2cConv.output.length
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

        RightSideTabView {
            anchors.fill:parent
            onChannelSelectChecked: {
                app.reloadPlotTracks()
            }
        }
    }

    WireSettingWindow {
        id: wsw
        channelModel: DisplaySetting.channelModel
        anchors.fill: parent
        // visible: false
        onAccepted: {
            ProcessManager.csv.run()
            app.reloadPlotTracks()

            ProcessManager.c2cConv.t1= 0
            ProcessManager.c2cConv.t2= ProcessManager.csv.output.length
            ProcessManager.c2cConv.channels = channels
            ProcessManager.c2cConv.inverse = inverses
            ProcessManager.c2cConv.type = type
            tracksListView.readyCount = 0
        }
    }

    ReportSettingWindow {
        id: reportSetting
        anchors.fill: parent
        reporter: ProcessManager.trn
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

    Action {
        id: centerSignal
        text: qsTr("&Center Signal")
        shortcut: "Alt+C"
        onTriggered: {
            for(let i = 0; i<tracksListView.count; i++) {
                tracksListView.itemAtIndex(i).signalFit()
            }
            gatherSignalView.itemAtIndex(0).signalFit()
            app.setT1T2(ProcessManager.trn.getT1() - 100, ProcessManager.trn.getT2() + 100)
        }
    }

    Action {
        id: zoomIn
        text: qsTr("Zoom In")
        shortcut: "Ctrl+Shift+A"
        onTriggered: {
            if(xAxis_.max - xAxis_.min < 200) return
            xAxis_.min += 100
            xAxis_.max -= 100

            // gatherSignalView.itemAtIndex(0).setT1T2(xAxis_.min, xAxis_.max)
        }
    }

    Action {
        id: zoomOut
        text: qsTr("Zoom Out")
        shortcut: "Ctrl+Shift+D"
        onTriggered: {
            if(xAxis_.max > ProcessManager.c2cConv.output.length - 100 || xAxis_.min < 100) return
            xAxis_.min -= 100
            xAxis_.max += 100

            // gatherSignalView.itemAtIndex(0).setT1T2(xAxis_.min, xAxis_.max)
        }
    }

    function refreshPlot() {
        ProcessManager.csv.refresh()
        delayUpdateTimer.restart()
    }

    function reloadPlotTracks() {
        loadedSignals.clear()
        gatherSignals.clear()
        ProcessManager.gatherModel.clear()
        tracksListView.readyCount = 0
        let colors = [
            'red',
            'blue',
            'green',
            'purple',
            'gray',
            'black',
            'yellow'
        ]
        let plotChannels = DisplaySetting.channelModel.getSelectedChannel()
        for(let i = 0; i < plotChannels.length; i++) {
            let ret = []
            for (let j = 0; j < plotChannels[i].length; j++) {
                ret.push({"plotChannel": plotChannels[i][j], "plotColor": colors[plotChannels[i][j] % colors.length]})
                gatherSignals.append({"plotChannel": plotChannels[i][j], "plotColor": colors[plotChannels[i][j] % colors.length]})
            }
            loadedSignals.set(i, ret)
            console.log(gatherSignals.count)
        }
        ProcessManager.gatherModel.append({})
        refreshPlot()
    }
    function setT1T2(t1, t2) {
        if(ProcessManager.sectionAxis.min != t1) 
            ProcessManager.sectionAxis.min = t1
        if(ProcessManager.sectionAxis.max != t2)
            ProcessManager.sectionAxis.max = t2
        if(sIndicate.startTime != t1)
            sIndicate.setStartTime(t1)
        if(sIndicate.endTime != t2)
            sIndicate.setEndTime(t2)
        if(lsIndicate.startTime != t1)
            lsIndicate.setStartTime(t1)
        if(lsIndicate.endTime != t2)
            lsIndicate.setEndTime(t2)
    }
    function setT1(t1) {
        if(sIndicate.startTime != t1)
            sIndicate.setStartTime(t1)
        if(lsIndicate.startTime != t1)
            lsIndicate.setStartTime(t1)
    }
    function setT2(t2) {
        if(sIndicate.endTime != t2)
            sIndicate.setEndTime(t2)
        if(lsIndicate.endTime != t2)
            lsIndicate.setEndTime(t2)
    }

    Connections {
        target: ProcessManager.sectionAxis
        function onMinChanged() {
            if(ProcessManager.sectionAxis.edited) {
                app.setT1T2(ProcessManager.sectionAxis.min, ProcessManager.sectionAxis.max)
                ProcessManager.sectionAxis.edited = false
            }
        }

        function onMaxChanged() {
            if(ProcessManager.sectionAxis.edited) {
                app.setT1T2(ProcessManager.sectionAxis.min, ProcessManager.sectionAxis.max)
                ProcessManager.sectionAxis.edited = false
            }
        }
    }
}
