import QtQuick 2.12
import QtQuick.Controls 2.12

import hcmusic.plot 1.0
import hcmusic.dsp 1.0

ListView {
    id: ruler

    property ValueAxis xValueAxis: ValueAxis {}
    property int totalSamples: 300300
    property int unitSamples: 3000
    property int viewSamples: 3000 * 5
    
    orientation: ListView.Horizontal
    model: (totalSamples / unitSamples).toFixed(0)
    contentX: (xValueAxis.min / viewSamples) * ruler.width
    interactive: false
    delegate: Item {
        width: ruler.width * unitSamples / (xValueAxis.max - xValueAxis.min )
        height: ruler.height
        Rectangle {
            width: 1
            height: parent.height
            anchors.left: parent.left
            anchors.top: parent.top
        }
        Text {
            text: index
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 3
            color: "white"
        }
    }
}