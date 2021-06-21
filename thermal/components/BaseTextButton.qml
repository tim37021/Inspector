import QtQuick 2.12
import QtQuick.Controls 2.12

import hcmusic.plot 1.0
import hcmusic.dsp 1.0

import ".."

Rectangle {
    id: root
    width : 100
    height: 60
    radius: 10
    color: {
        if(ma.pressed) return pressedColor;
        return ma.containsMouse? backgroundColor: hoverColor
    }
    property string backgroundColor: "#767575"
    property string hoverColor: "#808080"
    property string pressedColor: "#454545"
    property alias textColor: txt.color
    property alias text: txt.text

    signal clicked
    
    Text {
        id: txt
        color: "white"
        anchors.centerIn: parent
        text: "確認"
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            root.clicked()
        }
    }
}