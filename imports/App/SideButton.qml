import QtQuick 2.12
import QtQuick.Templates 2.12 as T
import QtGraphicalEffects 1.15

T.Button {
    id: control

    implicitWidth: background ? background.implicitWidth : 0
    implicitHeight: background ? background.implicitHeight : 0

    layer.enabled: true
    layer.effect: DropShadow {
        color: Qt.rgba(0, 0, 0, 0.1)
        transparentBorder: true
        horizontalOffset: 8
        verticalOffset: 8
    }

    autoExclusive: false
    checkable: false

    property alias radius: background.radius

    Rectangle {
        id: background
        anchors.fill: parent 

        Text {
            anchors.centerIn: parent
            text: control.text
        }
    }

    
    states: [
        State {
            name: "checked"
            when: control.checked
            PropertyChanges {
                target: background
                color: "#d4d4d4"
            }

        },
        State {
            name: "hover"
            when: control.hovered && !control.checked && !control.pressed

            PropertyChanges {
                target: background
                color: Qt.rgba(77/255, 81/255, 87/255, 1.0)
            }
        },
        State {
            name: "normal"
            when: !control.pressed && !control.checked && !control.hovered
            PropertyChanges {
                target: background
                color: Qt.rgba(55/255, 61/255, 69/255, 1.0)
            }
        },
        State {
            name: "pressed"
            when: control.pressed && !control.checked

            PropertyChanges {
                target: background
                color: "#b4b4b4"
            }
        }
    ]

}
