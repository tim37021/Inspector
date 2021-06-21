import QtQuick 2.12
import QtQuick.Controls 2.12

import hcmusic.plot 1.0
import hcmusic.dsp 1.0

import ".."

Item {
    id: root
    property alias windowColor: window.color
    signal accepted(var channels, var inverses)
    visible: root.opacity > 0.0
    opacity: 0.0

    Behavior on opacity { NumberAnimation { duration: 100 } }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.close()
        }
    }
    
    Rectangle {
        id: window
        anchors.centerIn: parent
        width: parent.width * 0.9
        height: parent.height * 0.9
        radius: 10

        color: "#6E6E6E"

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: false
            preventStealing: true
        }

        PWModeSelectView {
            id: pwm
            anchors.fill: parent
        }

        // Rectangle {
        //     anchors.right: parent.right; anchors.bottom: parent.bottom;
        //     anchors.margins: 10
        //     width : 100
        //     height: 60
        //     Text {
        //         anchors.centerIn: parent
        //         text: "確認"
        //     }
        //     MouseArea {
        //         anchors.fill: parent
        //         onClicked: {
        //             root.accepted(pwm.getChannels(), pwm.getInverses())
        //             root.close()
        //         }
        //     }
        // }

        BaseTextButton {
            anchors.right: parent.right; anchors.bottom: parent.bottom;
            anchors.margins: 10
            width : 100
            height: 60

            text: "確認"
            onClicked: {
                root.accepted(pwm.getChannels(), pwm.getInverses())
                root.close()
            }
        }

        Rectangle {
            anchors.right: parent.right; anchors.top: parent.top;
            anchors.margins: 10
            width : 30
            height: 30
            radius: width / 2
            color: "lightgray"
            AppIcon {
                anchors.fill: parent
                anchors.margins: 2
                color: "lightblack"
                iconType: AppIcon.Clear
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.close()
                }
            }
        }
    }

    function open() {
        root.opacity = 1.0
    }

    function close() {
        root.opacity = 0.0
    }
    
}
