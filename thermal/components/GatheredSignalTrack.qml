
import QtQuick 2.12
import QtQml 2.15
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.1
import App 1.0

import hcmusic.plot 1.0
import hcmusic.dsp 1.0

Item {
    id: root
    property Rectangle plotSection: plotSec
    property Signal1D source
    property string textColor: "white"
    property string infoText 
    property var model

    property ValueAxis xValueAxis: ValueAxis {
        min: 0
        max: root.source.length 
    }

    property ValueAxis yValueAxis: ValueAxis {
        min: -16384
        max: 16384
    }

    property alias mouseCoordX: spc.mouseCoordX
    property alias mouseCoordY: spc.mouseCoordY

    signal plotReady
    signal mouseEntered
    signal mouseLeaved

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
        id: plotSec
        anchors.top: parent.top; anchors.bottom: parent.bottom;
        anchors.left: infoSection.right; anchors.right: parent.right;
        color: "white"
        border.color: "gray"
        border.width: 1

        SignalPlotOpenGL {
            anchors.fill: parent
            focus: true

            Repeater {
                id: rep
                model: root.model
                delegate: BufferLineSeries {
                    id: ls
                    xAxis: xValueAxis
                    yAxis: yValueAxis
                    color: plotColor
                    lineWidth: 2
                    source: root.source
                    viewChannel: plotChannel
                }
            }
            
            SignalPlotControl {
                id: spc
                anchors.fill: parent
                xAxis: xValueAxis
                yAxis: yValueAxis
                lockX: true
                lockY: true
                lockScrollY: true
                hoverEnabled: true

                onContainsMouseChanged: {
                    if(containsMouse) root.mouseEntered()
                    else root.mouseLeaved()
                }
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
            propagateComposedEvents: true
        }

        

        Repeater {
            id: horizontalRep
            model: root.model
            delegate: Item {
                anchors.fill: parent
                Rectangle {
                    border.width: 2
                    border.color: plotColor
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
                        text: root.getNearestY(ma.mouseCoordX, index).toString()
                        color: "white"
                    }
                }

                Rectangle {
                    id: horizontalCrossHair
                    anchors.left: parent.left; anchors.right: parent.right;
                    height: 1
                    color: "gray"
                    y: (yValueAxis.max - root.getNearestY(ma.mouseCoordX, index)) / (yValueAxis.max - yValueAxis.min) * ma.height
                    visible: ma.containsMouse
                }
            }
        }

        Rectangle {
            id: verticalCrossHair
            anchors.top: parent.top; anchors.bottom: parent.bottom;
            width: 1
            color: "gray"
            x: ma.mouseX
            visible: ma.containsMouse
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

    function getNearestY(x, index) {
        return rep.itemAt(index).slice(x, 1)
    }
}