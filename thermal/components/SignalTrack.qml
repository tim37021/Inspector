
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

    Item {
        id: infoSection
        anchors.top:parent.top; anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        width: parent.width * 0.3

    }
    
    Rectangle {
        anchors.top:parent.top; anchors.bottom: parent.bottom;
        anchors.left: infoSection.right; anchors.right: parent.right;


        SignalPlotOpenGL {
            anchors.fill: parent
            focus: true
            ValueAxis {
                id: xAxis_
                min: 0
                max: ls.source.length 
            }

            ValueAxis {
                id: yAxis_
                min: -16384
                max: 16384
            }

            BufferLineSeries {
                id: ls
                xAxis: xAxis_
                yAxis: yAxis_
                color: "orange"
                lineWidth: 2
                source: null
                viewChannel: 0
            }
            
            SignalPlotControl {
                id: spc
                anchors.fill: parent
                xAxis: xAxis_
                yAxis: yAxis_
                lockX: true
                lockY: true
                lockScrollY: true
            }
        }
    }
    

    function signalFit() {
        xAxis_.min = 0
        xAxis_.max = source.length
        yAxis_.min = source.getChannelMin(viewChannel) - 10
        yAxis_.max = source.getChannelMax(viewChannel) + 10
    }
}