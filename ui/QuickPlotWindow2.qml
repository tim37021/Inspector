import QtQuick 2.12
import App 1.0
import hcmusic.plot 1.0
import inspector.dsp 1.0

SubWindow {
    property BaseNode node
    property var bvoutput: bv.output

    BufferView {
        id: bv
        input: node? node.output: null
        length: 44100
        channels: [0]
        onInputChanged: {
            length = node.output.length
            xAxis_.max = length
        }
        onOutputChanged: {
            console.log('yoyo')
        }
    }

    InteractivePlot {
        id: plot
        y: 24
        width: parent.width * 0.9
        height: parent.height * 0.8
        anchors.centerIn: parent
        drawGrid: true
        gridSizeX: bv.output.length / 10
        gridSizeY: 1000

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
            source: bv.output
            onSourceChanged: {
                console.log("gg"+source)
            }
        }

        Keys.onPressed: {
            if(event.key == 32) {
                node.running = !node.running
            }
        }
        Keys.onTabPressed: {
            bv.channels = [(bv.channels[0]+1) % bv.input.channels]
        }
    }

    function getArray() {
        if(noutput) {

        }
        return new Float32Array([]);
    }
}