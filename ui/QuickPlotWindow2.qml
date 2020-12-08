import QtQuick 2.12
import App 1.0
import hcmusic.plot 1.0
import inspector.dsp 1.0

SubWindow {
    property BaseNode node
    readonly property SignalOutput noutput: node? node.output: null

    InteractivePlot {
        id: plot
        y: 24
        width: parent.width * 0.9
        height: parent.height * 0.8
        anchors.centerIn: parent
        drawGrid: false
        gridSizeX: ls.length / 20
        gridSizeY: 500000

        xAxis: ValueAxis {
            id: xAxis_
            min: 0
            max: 4096
        }

        yAxis: ValueAxis {
            id: yAxis_
            min: -16384
            max: 16384
        }

        BufferLineSeries {
            id: ls
            xAxis: xAxis_
            yAxis: yAxis_
            color: Qt.rgba(247/255, 193/255, 121/255, 1.0)
            lineWidth: 2
            source: noutput
        }

        Keys.onPressed: {
            if(event.key == 32) {
                node.running = !node.running
            }
        }
    }

    function getArray() {
        if(noutput) {

        }
        return new Float32Array([]);
    }
}