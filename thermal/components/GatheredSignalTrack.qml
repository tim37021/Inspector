
import QtQuick 2.12
import QtQml 2.15
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.1
import App 1.0

import hcmusic.plot 1.0
import hcmusic.dsp 1.0

Item {
    id: root
    property ListModel signalModel
    property Signal1D input
    property int samplerate: 3000

    property ValueAxis xValueAxis: ValueAxis {}

    property ValueAxis yValueAxis: ValueAxis {}

    signal componentAdded

    Item {
        id: infoSection
        anchors.top:parent.top; anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        width: parent.width * 0.15

        Text {
            anchors.top:parent.top; anchors.right: parent.right
            text: (yValueAxis.max / 10).toFixed(0) * 10
            font.pixelSize: 12
        }
        Text {
            anchors.bottom:parent.bottom; anchors.right: parent.right
            text: (yValueAxis.min / 10).toFixed(0) * 10
            font.pixelSize: 12
        }
    }
    
    Rectangle {
        anchors.top:parent.top; anchors.bottom: parent.bottom;
        anchors.left: infoSection.right; anchors.right: parent.right;
        color: "white"
        border.color: "gray"
        border.width: 1

        SignalPlotOpenGL {
            id: canvas
            anchors.fill: parent
            focus: true

            Repeater {
                model: signalModel
                BufferLineSeries {
                    xAxis: xValueAxis
                    yAxis: yValueAxis
                    color: plotColor
                    lineWidth: 2
                    source: root.input
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
            }

        }
    }

    function signalFit() {
        xValueAxis.min = 0
        xValueAxis.max = samplerate * 5 // max for 5 seconds
        let yA = 0
        for(let i = 0; i < source.channels; i ++) {
            yA = Math.max(Math.abs(source.getChannelMin(i)), Math.abs(source.getChannelMax(i)))
        }
        if(yValueAxis.min > ( - yA - 10))
            yValueAxis.min =  - yA - 10

        if(yValueAxis.max < (yA + 10))
            yValueAxis.max = yA + 10
    }

}