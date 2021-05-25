import QtQuick 2.12
import QtQml 2.15
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.1
import App 1.0

import hcmusic.plot 1.0
import hcmusic.dsp 1.0

Item {
    id: root
    property ValueAxis axisX: ValueAxis {min: 100; max: 1000;}
    property real startX: 100
    property real endX: 200
    property real coordinateMin: (startX / width) * (axisX.max - axisX.min) + axisX.min
    property real coordinateMax: (endX / width) * (axisX.max - axisX.min) + axisX.min
    property string borderColor: "orange"
    property real minDiff: 1000

    property real hoverMouseX
    property real hoverMouseY

    property bool hoverOnDrag: leftMa.containsMouse || rightMa.containsMouse
    property bool hoverOnMinDrag: leftMa.containsMouse 
    property bool hoverOnMaxDrag: rightMa.containsMouse

    Item {
        id:section
        anchors.top: parent.top; anchors.bottom: parent.bottom;
        
        x: root.startX
        width: root.endX - root.startX
    }

    Rectangle {
        id: leftSection
        anchors.top: section.top; anchors.bottom: section.bottom;
        anchors.right: section.left;
        radius: 4;
        width: 20
        color: root.borderColor

        MouseArea {
            id: leftMa
            anchors.fill: parent
            drag.target: parent
            hoverEnabled: true
            property real dragStartX: 0.0
            onPressed: dragStartX = mouseX
            onMouseXChanged: {
                root.hoverMouseX = leftSection.x + mouseX
                root.hoverMouseY = leftSection.y + mouseY
                if(pressed) dragResizeLeft(mouseX - dragStartX)
            }
        }
    }

    Rectangle {
        id: rightSection
        anchors.top: section.top; anchors.bottom: section.bottom;
        anchors.left: section.right;
        radius: 4;
        width: 20
        color: root.borderColor

        MouseArea {
            id: rightMa
            anchors.fill: parent
            drag.target: parent
            hoverEnabled: true
            property real dragStartX: 0.0
            onPressed: dragStartX = mouseX
            onMouseXChanged: {
                root.hoverMouseX = rightSection.x + mouseX
                root.hoverMouseY = rightSection.y + mouseY
                if(pressed) dragResizeRight(mouseX - dragStartX)
            }
        }
    }

    Rectangle {
        id: topRect
        height: 4
        anchors.left: section.left; anchors.right: section.right;
        anchors.top: section.top;
        anchors.leftMargin: -4; anchors.rightMargin: -4; 
        color: root.borderColor
    }

    Rectangle {
        id: bottomRect
        height: 4
        anchors.left: section.left; anchors.right: section.right;
        anchors.bottom: section.bottom;
        anchors.leftMargin: -4; anchors.rightMargin: -4; 
        color: root.borderColor
    }

    function dragResizeLeft(mouseX) {
        let minDiffWidth = root.minDiff / (axisX.max - axisX.min) * root.width
        root.startX = root.startX + mouseX
        if(root.startX <= 0) root.startX = 0
        if(root.endX - root.startX <= minDiffWidth) root.startX = root.endX - minDiffWidth
    }

    function dragResizeRight(mouseX) {
        let minDiffWidth = root.minDiff / (axisX.max - axisX.min) * root.width
        root.endX = root.endX + mouseX
        if(root.endX >= root.width) root.endX = root.width
        if(root.endX - root.startX <= minDiffWidth) root.endX = root.startX + minDiffWidth
    }
}