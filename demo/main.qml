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

    function midi_to_note(mid) {
        return ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"][mid%12]
    }

    Image {
        anchors.centerIn: parent
        source: 'logo.png'
    }

    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        text: midi_to_note(Math.round(69 + Math.log2(synth.frequency/440)*12))
        color: "white"
    }

    SineSynth {
        id: synth
        rate: 44100
        frequency: 440
        length: 1024
        amplitude: slider.value
        Timer {
            running: true
            repeat: true
            interval: 1024 / 44100 * 1000 
            onTriggered: synth.synth()
        }
    }

    AudioInputDevice2 {
        id: aid
        active: false
        bufferLength: 1024
        rate: 32000
    }

    AudioOutputDevice2 {
        active: true
        bufferLength: 1024
        input: synth.output
        rate: 44100
    }
    RingBuffer {
        id: sb
        channels: 1
        length: 44100
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
            max: 32000 
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
            // source: sb.output
        }

        SignalPlotControl {
            anchors.fill: parent
            xAxis: xAxis_
            yAxis: yAxis_
        }

        Keys.onPressed: {
            if(event.key == 74)
                synth.frequency *= Math.pow(2, -1/12)
            if(event.key == 75)
                synth.frequency *= Math.pow(2, 1/12)
        }
    }
    Slider {
        id: slider
        from: 1
        to: 8000
        value: 2000
    }



}
