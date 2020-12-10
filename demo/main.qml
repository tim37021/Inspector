import QtQuick 2.12
import QtQuick.Controls 2.12
import inspector.dsp 1.0
import hcmusic.audio 1.0
import hcmusic.plot 1.0

ApplicationWindow {
    width: 800
    height: 600
    visible: true
    color: "black"
    title: 'NegativeGrid'

    Image {
        anchors.centerIn: parent
        source: 'logo.png'
    }
    
    AudioInputDevice2 {
        id: aid
        active: true
        bufferLength: 1024
        rate: 32000
    }

    StorageBuffer {
        id: sb
        channels: 1
        maxLength: 32000*2
        input: aid.output
        onFullChanged: {
            this.saveToNpz('yoyo.npz')
            console.log('saved')
        }
    }

    SignalPlotOpenGL {
        anchors.fill: parent
        ValueAxis {
            id: xAxis_
            min: 0
            max: 32000 * 2
        }

        ValueAxis {
            id: yAxis_
            min: -16384
            max: 16384
        }

        BufferLineSeries {
            xAxis: xAxis_
            yAxis: yAxis_
            color: "orange"
            lineWidth: 2
            source: sb.output
        }
    }

    AudioOutputDevice2 {
        active: true
        bufferLength: 1024
        input: aid.output
        rate: 32000
    }
}
