import QtQuick 2.12
import QtQuick.Controls 2.12
import hcmusic.audio 1.0
import hcmusic.plot 1.0
import hcmusic.dsp 1.0
import hcmusic.licap 1.0

ApplicationWindow {
    width: 800
    height: 600
    visible: true
    color: "black"
    title: 'NegativeGrid'
    property bool isfft: false

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

//    LiCAPv1 {

//    }

    SineSynth {
        id: synth
        rate: 32000
        frequency: 440
        length: 1024
        amplitude: 2000
        Timer {
            running: false
            repeat: true
            interval: 1024 / 32000 * 1000 
            onTriggered: synth.synth()
        }
    }

    AudioInputDevice2 {
        id: aid
        active: true
        bufferLength: 1024
        rate: 32000
    }

    AudioOutputDevice2 {
        active: true
        bufferLength: 1024
        input: aid.output
        rate: 32000
    }
    AutoCorrelation {
        id: ac
        input: aid.output
        rate: 32000
    }
    FFT {
        id: fft
        input: aid.outpust
        rate: 32000

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
            source: ac.output
        }
        
        BufferLineSeries {
            id: ls2
            xAxis: xAxis_
            yAxis: yAxis_
            color: "blue"
            lineWidth: 2
            source: fft.output
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
    Button {
        id: btn
        text: isfft?'fft':'ac'
        onClicked: isfft = !isfft
    }

}
