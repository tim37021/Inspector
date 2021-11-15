import QtQuick 2.12
import QtQuick.Controls 2.12
import hcmusic.plot 1.0
import hcmusic.dsp 1.0
import hcmusic.licap 1.0
import hcmusic.midi 1.0

Item {
    id: root
    property alias input: rb.input
    property alias length: rb.length
    property alias channel: ls.viewChannel
    property string lineColor: "red"
    property ValueAxis xAxis: ValueAxis {
        min: 0
        max: 1024
    }
    property ValueAxis yAxis: ValueAxis {
        min: -16384
        max: 16384
    }
    property int lineWidth: 2

    RingBuffer {
        id: rb
        channels: 6
        length: 1024
    }

    SignalPlotOpenGL{
        anchors.fill: parent
        focus: true
        BufferLineSeries {
            id: ls
            xAxis: root.xAxis
            yAxis: root.yAxis
            color: root.lineColor
            lineWidth: root.lineWidth
            source: rb.output
        }
        SignalPlotControl {
            id: spc
            anchors.fill: parent
            xAxis: root.xAxis
            yAxis: root.yAxis
        }
    }
}