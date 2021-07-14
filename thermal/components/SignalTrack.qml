
import QtQuick 2.12
import QtQml 2.15
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.1
import App 1.0

import hcmusic.plot 1.0
import hcmusic.dsp 1.0

Item {
    id: root
    property alias viewChannel: ls.viewChannel
    property alias source: ls.source
    property alias lineColor: ls.color
    property string infoText 
    property string textColor: "white"

    property bool showHoverY: true

    property ValueAxis xValueAxis: ValueAxis {
        min: 0
        max: ls.source.length 
    }

    property ValueAxis yValueAxis: ValueAxis {
        min: -16384
        max: 16384
    }

    signal plotReady

    Item {
        id: infoSection
        anchors.top:parent.top; anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        width: Math.min(parent.width * 0.15, 80)

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 5
            text: root.infoText
            color: root.textColor
        }

        Text {
            anchors.top:parent.top; anchors.right: parent.right
            text: (yValueAxis.max / 10).toFixed(0) * 10
            font.pixelSize: 12
            color: root.textColor
        }
        Text {
            anchors.bottom:parent.bottom; anchors.right: parent.right
            text: (yValueAxis.min / 10).toFixed(0) * 10
            font.pixelSize: 12
            color: root.textColor
        }
    }
    
    Rectangle {
        anchors.top:parent.top; anchors.bottom: parent.bottom;
        anchors.left: infoSection.right; anchors.right: parent.right;
        color: "white"
        border.color: "gray"
        border.width: 1

        SignalPlotOpenGL {
            anchors.fill: parent
            focus: true

            ListModel {
                id: pointModel
                ListElement {px: 0; py: 0;}
            }

            BufferLineSeries {
                id: ls
                xAxis: xValueAxis
                yAxis: yValueAxis
                color: "orange"
                lineWidth: 2
                source: null
                viewChannel: 0
            }
            
            SignalPlotControl {
                id: spc
                anchors.fill: parent
                xAxis: xValueAxis
                yAxis: yValueAxis
                lockY: true
                lockScrollY: true
            }

            onPlotReady: {
                root.plotReady()
            } 
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            property real mouseCoordX: (mouseX / width) * (xValueAxis.max - xValueAxis.min) + xValueAxis.min
            property real mouseCoordY: (mouseY / height) * (yValueAxis.max - yValueAxis.min) + yValueAxis.min

            hoverEnabled: true
        }

        Rectangle {
            id: horizontalCrossHair
            anchors.left: parent.left; anchors.right: parent.right;
            height: 1
            color: "gray"
            y: (yValueAxis.max - root.getNearestY(ma.mouseCoordX)) / (yValueAxis.max - yValueAxis.min) * ma.height
            visible: ma.containsMouse
        }

        Rectangle {
            id: verticalCrossHair
            anchors.top: parent.top; anchors.bottom: parent.bottom;
            width: 1
            color: "gray"
            x: ma.mouseX
            visible: ma.containsMouse
        }

        Rectangle {
            border.width: 2
            border.color: "#222222"
            color: "#2E2E2E"
            width: 60
            height: 30
            anchors.verticalCenter: horizontalCrossHair.verticalCenter
            anchors.right: parent.left;
            anchors.rightMargin: 2
            visible: ma.containsMouse
            clip: true

            Text {
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter;
                anchors.leftMargin: 2
                text: root.getNearestY(ma.mouseCoordX).toString()
                color: "white"
            }
        }

        Item {
            width: 60
            height: 30
            anchors.left: verticalCrossHair.horizontalCenter
            anchors.bottom: parent.bottom;
            anchors.leftMargin: 2
            visible: ma.containsMouse
            clip: true

            Text {
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter;
                anchors.leftMargin: 2
                text: ma.mouseCoordX.toFixed(0).toString()
                color: "black"
            }
        }
    }

    function getNearestY(x) {
        return ls.slice(x, 1)
    }
}