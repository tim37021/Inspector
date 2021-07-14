
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
    property ListModel model: ListModel {
        ListElement {
            plotColor: "red"
            plotChannel: 10
        }
        ListElement {
            plotColor: "blue"
            plotChannel: 11
        }
        ListElement {
            plotColor: "green"
            plotChannel: 12
        }
        ListElement {
            plotColor: "yellow"
            plotChannel: 13
        }
        
        ListElement {
            plotColor: "gray"
            plotChannel: 14
        }
        ListElement {
            plotColor: "black"
            plotChannel: 15
        }
        ListElement {
            plotColor: "orange"
            plotChannel: 16
        }
        ListElement {
            plotColor: "darkgray"
            plotChannel: 17
        }
    }

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
                // lockX: true
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
    }
}