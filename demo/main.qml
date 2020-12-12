import QtQuick 2.12
import QtQuick.Controls 2.12
import hcmusic.audio 1.0
import hcmusic.plot 1.0
import hcmusic.dsp 1.0

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

    SineSynth {
        id: synth
        rate: 32000
        frequency: 441
        length: 1024
        valueScale: 2000
        Timer {
            running: true
            repeat: true
            interval: 32000 / 1024
            onTriggered: synth.synth()
        }
    }

    AudioInputDevice2 {
        id: aid
        active: true
        bufferLength: 1024
        rate: 32000
    }

    RingBuffer {
        id: sb
        channels: 1
        length: 32000*2
        input: synth.output

        //onFullChanged: {
            // this.saveToNpz('yoyo.npz')
            // console.log('saved')
        //}
    }

    SignalPlotOpenGL {
        anchors.fill: parent
        focus: true
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

        SignalPlotControl {
            anchors.fill: parent
            xAxis: xAxis_
            yAxis: yAxis_
        }

        Keys.onPressed: {
            if(event.key == 74)
                synth.frequency-=5
            if(event.key == 75)
                synth.frequency+=5
        }
    }

    AudioOutputDevice2 {
        active: true
        bufferLength: 1024
        input: synth.output
        rate: 32000
    }

}
