import QtQuick 2.12
import QtQuick.Controls 2.12
import App 1.0

import ".."


Item {
    anchors.fill: parent;
    anchors.margins: 10

    property alias topModel: itTop.model
    property alias bottomModel: itLow.model

    Item {
        id: itTopArea
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right;
        // anchors.margins: 10
        height: 60

        InfoTable2 {
            id: itTop
            anchors.fill: parent
            headerNames: ["", "Cursor1", "Cursor2", "CursorDiff"]
            headerColor: appMaterial.surface1
            borderColor:appMaterial.surface2
            fontColor: appMaterial.text
            fontFamily: appMaterial.fontFamily
        }
    }

    Item {
        id: itBottomArea
        anchors.top: itTopArea.bottom; anchors.bottom: parent.bottom; 
        anchors.left: parent.left; anchors.right: parent.right;

        InfoTable2 {
            id: itLow
            anchors.fill: parent
            
            headerColor: appMaterial.surface1
            borderColor:appMaterial.surface2
            fontColor: appMaterial.text
            fontFamily: appMaterial.fontFamily
        }
    }        
}
