import QtQuick 2.12
import QtGraphicalEffects 1.15

Rectangle {
    id: control
    readonly property alias hovered: ma.containsMouse
    readonly property alias pressed: ma.containsPress
    property alias text: txt.text
    property alias font: txt.font

    layer.enabled: true
    layer.effect: DropShadow {
        color: Qt.rgba(0, 0, 0, 0.1)
        transparentBorder: true
        horizontalOffset: 8
        verticalOffset: 8
    }

    Text {
        id: txt
        anchors.centerIn: parent
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
    }


    
    states: [
        State {
            name: "hover"
            when: control.hovered && !control.pressed

            PropertyChanges {
                target: control
                color: Qt.rgba(77/255, 81/255, 87/255, 1.0)
            }
        },
        State {
            name: "normal"
            when: !control.hovered && !control.pressed
            PropertyChanges {
                target: control
                color: Qt.rgba(55/255, 61/255, 69/255, 1.0)
            }
        },
        State {
            name: "pressed"
            when: control.pressed

            PropertyChanges {
                target: control
                color: "#b4b4b4"
            }
        }
    ]

}