import QtQuick 2.12
import QtQuick.Controls 2.12

import hcmusic.plot 1.0
import hcmusic.dsp 1.0

import ".."

Item {
    id: root
    property alias windowColor: window.color
    property alias channelModel: channelSelect.channelModel

    signal accepted(var channels, var inverses, var type)
    visible: root.opacity > 0.0
    opacity: 0.0

    Behavior on opacity { NumberAnimation { duration: 100 } }
    
    AppMaterial { id: appMaterial }

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

        color: appMaterial.surface4

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: false
            preventStealing: true
        }

        Item {
            id: pwmSection
            anchors.verticalCenter: parent.verticalCenter;
            anchors.left: parent.left
            width: parent.width * 0.8
            height: parent.height

            PWModeSelectView {
                id: pwm
                anchors.fill: parent
            }
        }

        Text {
            anchors.bottom: showChannelSetting.top; anchors.left: showChannelSetting.left;
            font.pixelSize: 18
            text: "預覽訊號"
            color: "white"
        }

        Rectangle {
            id: showChannelSetting
            anchors.left: pwmSection.right; anchors.right: parent.right;
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 10
            height: parent.height * 0.7
            color: "transparent"
            border.color: "#E0E0E0"
            border.width: 2
            radius: 5
            clip: true

            ChannelSelectBox {
                id: channelSelect
                anchors.fill: parent
            }
        }

        BaseTextButton {
            anchors.right: parent.right; anchors.bottom: parent.bottom;
            anchors.margins: 10
            width : 100
            height: 60

            text: "確認"
            onClicked: {
                root.accepted(pwm.getChannels(), pwm.getInverses(), pwm.phaseWireType)
                root.close()
            }
        }

        BaseIconButton {
            anchors.right: parent.right; anchors.top: parent.top;
            anchors.margins: 10
            width : 30
            height: 30
            backgroundColor: appMaterial.error
            hoverColor: appMaterial.surface2
            pressedColor: appMaterial.errorOn
            onClicked: root.close()
        }
    }

    function open() {
        root.opacity = 1.0
    }

    function close() {
        root.opacity = 0.0
    }
}
