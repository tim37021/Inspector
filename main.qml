import QtQuick 2.12
import QtQuick.Controls 2.12
import nrf.beacon 1.0
import App 1.0

import QtQuick.Dialogs 1.3
import Buffer 1.0
import hcmusic.utils 1.0


ApplicationWindow {
    id: app
    width: Constants.width
    height: Constants.height
    visible: true
    color: Constants.background

    Component {
        id: buf_comp
        RawBufferView {
            property alias filename: nb.filename
            sourceBuffer: NumpyBuffer {
                id: nb
            }
        }
    }

    FileDialog {
        id: ofd
        nameFilters: [ "npz files (*.npz)" ]
        onAccepted: {
            let buf = buf_comp.createObject(null, {filename: fileUrl})
            app.createQuickPlotWindow('plot', buf)
        }
    }

    property DeviceManager deviceMgr: DeviceManager {
        onDevicePlugged: {
            tm.message(`New device found: ${port}`)
        }
        onDeviceUnplugged: {
            tm.message(`${port} is unplugged`)
        }
    }

    SideBar {
        id: sb
        color: Constants.foreground1
        content: Column {
            anchors.fill: parent
            spacing: 16
            
            ListView {
                model: app.deviceMgr.enumModel
                spacing: 16

                width: parent.width
                height: 48 * count + 16 * (count-1)
                delegate: DeviceButton {
                    id: deviceBtn
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * 0.8
                    height: 48
                    scanner: app.deviceMgr.getScanner(display)
                    port: display

                    property SubWindow window

                    Connections {
                        target: app.deviceMgr.getScanner(display)
                        function onStateChanged(v) {
                            if(target.state == BeaconScanner.Scanning && deviceBtn.window == null) {
                                deviceBtn.window = app.createPlotWindow(display, scanner.model)
                                app.createRaceWindow(`Runners (${display})`, scanner.model)
                            }

                        }
                    }
                }

            }
            
            SideButton {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.8
                height: 48
                text: '+'
                onClicked: ofd.open()
            }

            

        }
        
        
    }

    ///> Windowing system for this app
    Windowing {
        id: windowing
    }

    Component {
        id: plotWindowComp
        PlotWindow {
            width: app.width * 0.8
            height: app.height * 0.8
        }
    }

    Component {
        id: quickPlotWindowComp
        QuickPlotWindow {
            width: app.width * 0.8
            height: app.height * 0.8
        }
    }

    Component {
        id: raceWindowComp
        RaceWindow {
            x: app.width - width - 16
            y: app.height - height - 16
            width: app.width * 0.4
            height: app.height * 0.3
        }
    }

    Component {
        id: imageWindowComp
        ImageWindow {
            width: app.width * 0.8
            height: app.height * 0.8
        }
    }

    /**
     * createPlotWindow
     * @param title Title of the new window
     * @param mdl Instance of TrackedDeviceModel
     */
    function createPlotWindow(title, mdl) {
        return windowing.createWindow(plotWindowComp, {open: true, title: title, target: mdl});
    }

    /**
     * createQuickPlotWindow
     * @param title Title of the new window
     * @param source Signal source. Can be raw array
     */
    function createQuickPlotWindow(title, source) {
        return windowing.createWindow(quickPlotWindowComp, {open: true, title: title, signalSource: source});
    }

    /**
     * createImageWindow
     * @param title Title of the new window
     * @param raw image ArrayBuffer(BGR888)
     */
    function createImageWindow(title, source) {
        return windowing.createWindow(imageWindowComp, {open: true, title: title, signalSource: source});
    }

    /**
     * createRaceWindow
     * @param title Title of the new window
     * @param mdl Instance of TrackedDeviceModel
     */
    function createRaceWindow(title, mdl) {
        return windowing.createWindow(raceWindowComp, {open: true, title: title, target: mdl});
    }

    function moveToTop(window) {
        windowing.moveToTop(window)
    }

    function notify(msg) {
        tm.message(msg)
    }

    ListView {
        id: lv
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        
        width: 256+16
        height: 48 * count + 16 * (count - 1) + 16
        spacing: 16

        model: TimeoutModel {
            id: tm
            property string s: ''
            function message(msg) {tm.update(s, {text: msg}); s+='A'}
        }

        delegate: Notification {
            text: model.text
            width: 256
            height: 48
            radius: 2
            opacity: 1.0
        }
    }

    Component.onCompleted: {
        console.log('tim: Don\'t worry, these warnings are QT\'s bugs')
        
    }

}

