import QtQuick 2.12
import QtQuick.Controls 2.12

import hcmusic.plot 1.0
import hcmusic.dsp 1.0

import ".."

Item {
    id: root
    property ListModel channelModel: ListModel {}
    AppMaterial { id: appMaterial }


    ListView {
        id: lv
        anchors.fill: parent
        model: channelModel
        delegate: selectChannelDelegate
        ScrollBar.vertical: ScrollBar {}
    }

    Component {
        id: selectChannelDelegate

        Item {
            width: showChannelSetting.width * 0.9
            height: 50

            CheckBox {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                checked: value
                onCheckedChanged: {
                    channelModel.setProperty(index, "value", checked)
                }
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: "white"
                text: name
            }
        }
    }
}