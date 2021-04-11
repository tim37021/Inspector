
import QtQuick 2.12
import QtQml 2.15
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.1
import App 1.0

import hcmusic.plot 1.0
import hcmusic.dsp 1.0

Item {
    property alias viewChannel: ls.viewChannel
    property alias source: ls.source
    property alias lineColor: ls.color
    property int samplerate: 3000

    property ValueAxis xValueAxis: ValueAxis {
        min: 0
        max: ls.source.length 
    }

    property ValueAxis yValueAxis: ValueAxis {
        min: -16384
        max: 16384
    }

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
            anchors.fill: parent
            focus: true

            BufferLineSeries {
                id: ls
                // xAxis: xAxis_
                // yAxis: yAxis_
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
                // xAxis: xAxis_
                // yAxis: yAxis_
                xAxis: xValueAxis
                yAxis: yValueAxis
                // lockX: true
                lockY: true
                lockScrollY: true
            }
        }
    }
    

    function signalFit() {
        xValueAxis.min = 0
        xValueAxis.max = samplerate * 5 // max for 5 seconds
        let yA = Math.max(Math.abs(source.getChannelMin(viewChannel)), Math.abs(source.getChannelMax(viewChannel)))
        if(yValueAxis.min > ( - yA - 10))
            yValueAxis.min =  - yA - 10

        if(yValueAxis.max < (yA + 10))
            yValueAxis.max = yA + 10
    }
}