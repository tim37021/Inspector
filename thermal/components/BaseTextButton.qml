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
    AppMaterial { id: appMaterial }
    color: {
        if(ma.pressed) return pressedColor;
        return ma.containsMouse? hoverColor: backgroundColor
    }
    property string backgroundColor: appMaterial.secondary
    property string hoverColor: appMaterial.surface2
    property string pressedColor: appMaterial.surface1
    property alias textColor: txt.color
    property alias text: txt.text

    signal clicked
    
    Text {
        id: txt
        color: appMaterial.text
        anchors.centerIn: parent
        text: "確認"
        font.family: appMaterial.fontFamily
        font.bold: true
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