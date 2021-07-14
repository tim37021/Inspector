import QtQuick 2.12
import QtQuick.Controls 2.12

import hcmusic.plot 1.0
import hcmusic.dsp 1.0

import ".."

Rectangle {
    id: root
    width : 30
    height: 30
    radius: width / 2
    AppMaterial { id: appMaterial }
    color: {
        if(ma.pressed) return pressedColor;
        return ma.containsMouse? hoverColor: backgroundColor
    }
    property string backgroundColor: appMaterial.primary
    property string hoverColor: appMaterial.primaryOn
    property string pressedColor: appMaterial.primaryVariant
    property alias iconType: icon.iconType

    signal clicked
    
    AppIcon {
        id: icon
        anchors.fill: parent
        anchors.margins: 2
        color: "white"
        iconType: AppIcon.Clear
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