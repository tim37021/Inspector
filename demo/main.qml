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
        let n = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"][mid%12]
        return n+(Math.floor(mid / 12)-1)
    }

    Image {
        anchors.centerIn: parent
        source: 'logo.png'
    }

    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        text: midi_to_note(Math.round(69 + Math.log2(ac.frequency/440)*12))
        color: "white"
        font.pointSize: 24
    }

    SineSynth {
        id: synth
        rate: 44100
        frequency: 440
        length: 1024
        amplitude: slider.value
        Timer {
            running: false
            repeat: true
            interval: 1024 / 44100 * 1000 
            onTriggered: synth.synth()
        }
    }

    AudioInputDevice2 {
        id: aid
        active: true
        bufferLength: 1024
        rate: 44100
    }

    AudioOutputDevice2 {
        active: true
        bufferLength: 1024
        input: aid.output
        rate: 44100
    }
    AutoCorrelation {
        id: ac
        input: aid.output
        rate: 44100
    }
    FFT {
        id: fft
        input: aid.output
        rate: 44100

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
            max: ac.output.length 
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
            source: ac.output
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
