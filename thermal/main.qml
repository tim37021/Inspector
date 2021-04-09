
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

    CsvLoader { id: csv }

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
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right;
            anchors.bottom: lower.top;

            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right;
                height: 60
                SignalTrack {
                    id: strack
                    source: csv.output
                    viewChannel: 0
                    anchors.fill: parent

                    Component.onCompleted: this.signalFit()

                    Connections {
                        target: csv
                        function onUpdate() {
                            strack.signalFit()
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

            MouseArea {
                anchors.top: parent.top; anchors.right: parent.right;
                anchors.left: parent.left;
                height: 10
                property real startY: 0.0
                cursorShape: Qt.SizeVerCursor
                enabled: lower.width > 0

                onMouseXChanged: lower.height -=  mouseY - startY
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

            onMouseXChanged: rightView.width -=  mouseX - startX
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
