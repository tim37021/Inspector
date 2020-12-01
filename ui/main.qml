import QtQuick 2.12
import QtQuick.Controls 2.12
import nrf.beacon 1.0
import App 1.0

import QtQuick.Dialogs 1.1
import hcmusic.audio 1.0
import hcmusic.pyutils 1.0
import hcmusic.utils 1.0
import QtWebSockets 1.8

import hcmusic.licap 1.0

ApplicationWindow {
    id: app
    width: Constants.width
    height: Constants.height
    visible: true
    color: Constants.background
    title: 'Inspector'

    VCPEnumModel {
        id: vcpScanner
        running: true
        idFilter: /0483:.*/
        property string result
        onCompleted: {
            if(list.length > 0) {
                result = list[0]
                running = false
            }
        }
    }

<<<<<<< HEAD
=======

    LiCAPDevice {
        id: licap
    }

>>>>>>> 5f3985dae2830439f24ff0da862b025fc856fbd7
    AudioOutputDevice {
        id: od
        rate: 44100
    }
    


    Component {
        id: buf_comp
        RawBufferView {
            property alias filename: nb.filename
            sourceBuffer: NpzFile {
                id: nb
            }
        }
    }

    Component {
        id: buf_comp2
        RawBufferView {
            sourceBuffer: AudioInputDevice {
                recording: true
            }
        }
    }

    Component {
        id: buf_comp3
        RawBufferView {
            sourceBuffer: LiCAPDevice {
                port: vcpScanner.result
                recording: true
                deviceType: 1
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

    FileDialog {
        id: sfd
        nameFilters: [ "npz files (*.npz)" ]
        selectExisting: false
        onAccepted: {
            windowing.focusedWindow.signalSource.saveToFile(fileUrl)
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

    SideToolbar {
        x: parent.width - width - 16
        anchors.verticalCenter: parent.verticalCenter
        width: 50
        height: 200

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
                onClicked: contextMenu.open()
                
                Menu {
                    id: contextMenu
                    x: parent.width / 2
                    y: parent.height
                    MenuItem {
                        text: "Open Files (*.npz)"
                        onClicked: ofd.open()
                    }
                    MenuItem {
                        text: "From Microphone"
                        onClicked: {
                            let buf = buf_comp2.createObject(null)
                            app.createQuickPlotWindow('plot', buf)
                        }
                    }
                    MenuItem {
                        text: "From LiCAP"
                        onClicked: {
                            let buf = buf_comp3.createObject(null)
                            app.createQuickPlotWindow('plot', buf)
                        }
                    }
                    
                }
            }

            

        }
        
        
    }

    ///> Windowing system for this app
    Windowing {
        id: windowing
    }

    WindowFactory {
        id: wf
    }

    /**
     * createPlotWindow
     * @param title Title of the new window
     * @param mdl Instance of TrackedDeviceModel
     */
    function createPlotWindow(title, mdl) {
        return windowing.createWindow(wf.fetch('plot'), {open: true, title: title, target: mdl});
    }

    /**
     * createQuickPlotWindow
     * @param title Title of the new window
     * @param source Signal source. Can be raw array
     */
    function createQuickPlotWindow(title, source) {
        return windowing.createWindow(wf.fetch('quickplot'), {open: true, title: title, signalSource: source});
    }

    /**
     * createImageWindow
     * @param title Title of the new window
     * @param raw image ArrayBuffer(BGR888)
     */
    function createImageWindow(title, source) {
        return windowing.createWindow(wf.fetch('image'), {open: true, title: title, signalSource: source});
    }

    /**
     * createRaceWindow
     * @param title Title of the new window
     * @param mdl Instance of TrackedDeviceModel
     */
    function createRaceWindow(title, mdl) {
        return windowing.createWindow(wf.fetch('race'), {open: true, title: title, target: mdl});
    }

    function moveToTop(window) {
        windowing.moveToTop(window)
    }

    /**
     * notify
     * @param msg Notification
     */
    function notify(msg) {
        tm.message(String(msg))
    }

    /**
     * playBuffer
     * @param buffer to play
     */
    function playBuffer(buffer, rate) {
        od.play(buffer, rate)
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
}

