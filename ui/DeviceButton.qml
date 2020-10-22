import QtQuick 2.12
import QtQuick.Controls 2.12
import nrf.beacon 1.0
import QtGraphicalEffects 1.15

Rectangle {
    property string port 
    property BeaconScanner scanner

    color: ma.containsMouse? Qt.rgba(77/255, 81/255, 87/255, 1.0): Qt.rgba(55/255, 61/255, 69/255, 1.0)
    
    layer.enabled: true
    layer.effect: DropShadow {
        color: Qt.rgba(0, 0, 0, 0.1)
        transparentBorder: true
        horizontalOffset: 8
        verticalOffset: 8
    }

    Rectangle {
        id: statusLight
        x: 16
        width: 8
        height: 8
        radius: 4

        anchors.verticalCenter: parent.verticalCenter

        color: {
            switch(scanner.state) {
            case BeaconScanner.Closed: return "red";
            case BeaconScanner.Opening: return "yellow";
            case BeaconScanner.Opened: return "green"
            case BeaconScanner.Scanning: return "green";
            }

            return "red"
        }
    }

    Text {
        anchors.centerIn: parent
        text: port
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: scanner.open()
        //onDoubleClicked: app.createPlotWindow(port, scanner.model)
    }

    Button {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right 
        width: 32
        height: 32

        
        visible: scanner.state != BeaconScanner.Closed
        onClicked: scanner.running = !scanner.running
    }
} 
