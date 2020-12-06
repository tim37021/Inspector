import QtQuick 2.12
import QtQuick.Controls 2.12
import App 1.0

import QtQuick.Dialogs 1.1
import hcmusic.audio 1.0
import hcmusic.pyutils 1.0
import hcmusic.utils 1.0
import QtWebSockets 1.8

import hcmusic.licap 1.0
import inspector.dsp 1.0

ApplicationWindow {
    id: app
    width: Constants.width
    height: Constants.height
    visible: true
    color: Constants.background
    title: 'Inspector'
/*
    VCPEnumModel {
        id: vcpScanner
        running: true
        property string result
        onCompleted: {
            if(list.length > 0) {
                result = list[0]
                running = false
            }
        }
    }
*/

    LiCAPDevice {
        id: licap
    }

    AudioDiscoveryModelProvider {
        id: provider
    }

    ListView {
        width: 100
        height: 100
        anchors.centerIn: parent
        model: provider.inputDeviceModel
        delegate: Text {
            text: (provider.defaultInputDeviceIndex==model.deviceIndex?'*':'') + model.name
            color: "white"
        }
    }

    AudioInputDevice2 {
        id: aid2
        rate: 44100
        active: true
        bufferLength: 1024
        deviceIndex: provider.defaultInputDeviceIndex
    }

    AudioOutputDevice {
        id: od
        rate: 32000
        onRateChanged: {
            console.log(rate)
        }
    }

    Component {
        id: buf_comp
        NpzFile {
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
            }
        }
    }

    Component {
        id: buf_comp4
        StorageBuffer {
            input: aid2.output
            bufferLength: 16
            channels: 1
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
                            let win = app.createQuickPlotWindow('plot')
                            let buf = buf_comp4.createObject(win)
                            win.signalSource = buf.output
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
     * createQuickPlotWindow
     * @param title Title of the new window
     * @param source Signal source. Can be raw array
     */
    function createQuickPlotWindow(title, source) {
        return windowing.createWindow(wf.fetch('quickplot'), {open: true, title: title});
    }

    /**
     * createImageWindow
     * @param title Title of the new window
     * @param raw image ArrayBuffer(BGR888)
     */
    function createImageWindow(title, source) {
        return windowing.createWindow(wf.fetch('image'), {open: true, title: title, signalSource: source});
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

