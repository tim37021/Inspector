
import QtQuick 2.12
import QtQuick.Controls 2.12
import hcmusic.audio 1.0
import hcmusic.plot 1.0
import hcmusic.dsp 1.0
import hcmusic.licap 1.0
import hcmusic.midi 1.0

ApplicationWindow {
    width: 800
    height: 600
    visible: true
    color: "black"
    title: 'NegativeGrid' + `${spc.mouseCoordX}`+ '  ' +`${spc.mouseCoordY}`

    function midi_to_note(mid) {
        let n = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"][mid%12]
        return n+(Math.floor(mid / 12)-1)
    }

    // Image {
    //     anchors.centerIn: parent
    //     source: 'logo.png'
    // }
    LiCAPv1 {
        id: lid
        active: true
        port: '/dev/cu.usbmodem317B396C32371'
        bufferLength: 1024
        onError: {
            console.log(message)
        }
    }

    AmplitudeNode {
        id: amplitudeNode
        input: lid.output
        channels: 6
        length: 1024 * 10
    }

    // LiCAPv2 {
    //     id: lid
    //     active: true
    //     port: '/dev/cu.usbmodem3254395330381'
    //     bufferLength: 1024
    //     onError: {
    //         console.log(message)
    //     }
    // }

    MidiDiscoveryModelProvider{
        id: midiP
    }

    MidiOutputDevice {
        id:midiout
        portName: "LiCAP MIDI Device"
    }

    SineSynth {
        id: synth
        rate: 32000
        frequency: 440
        length: 256
        amplitude: 2000
        Timer {
            running: false
            repeat: true
            interval: parent.frequency / 32000 * 1000 
            onTriggered: synth.synth()
        }
    }

    PitchTracker {
        id: pt1
        input: lid.output
        rate: 32000
        channel: 5
        debug: true

        onOnset: {
            midiout.note_on(1, note + tp1.value,  Math.min(127, Math.floor(127*ap1.amplitude/1000000)))
        }
        onOffset: {
            midiout.note_off(1, noteOnset + tp1.value, 0)
        }
        onPitchbend: {
            midiout.pitchwheel(1, pitchbend)
        }
        onSustain: midiout.aftertouch(1, Math.min(127, Math.floor(127*ap1.amplitude/1000000)))

        Amplitude {
            id: ap1
            input: lid.output
            offset: 128
            channel: 5
            // onAmplitudeChanged: {
            //     console.log(amplitude)
            // }
        }
    }

    PitchTracker {
        id: pt2
        input: lid.output
        rate: 32000
        channel: 4

        onOnset: midiout.note_on(2, note + tp2.value, Math.min(127, Math.floor(127*ap2.amplitude/500000)))
        onOffset: {
            midiout.note_off(2, noteOnset + tp2.value, 0)
        }
        onPitchbend: {
            midiout.pitchwheel(2, pitchbend)
        }
        onSustain: midiout.aftertouch(2, Math.min(127, Math.floor(127*ap2.amplitude/500000)))

        Amplitude {
            id: ap2
            input: lid.output
            offset: 128
            channel: 4
        }
    }

    PitchTracker {
        id: pt3
        input: lid.output
        rate: 32000
        channel: 1

        onOnset: midiout.note_on(3, note + tp3.value, Math.min(127, Math.floor(127*ap3.amplitude/6000000)))
        onOffset: {
            midiout.note_off(3, noteOnset + tp3.value, 0)
        }
        onPitchbend: {
            midiout.pitchwheel(3, pitchbend)
        }
        onSustain: midiout.aftertouch(3, Math.min(127, Math.floor(127*ap3.amplitude/6000000)))

        Amplitude {
            id: ap3
            input: lid.output
            offset: 128
            channel: 1
        }
    }

    PitchTracker {
        id: pt6
        input: lid.output
        rate: 32000
        channel: 2

        onOnset: midiout.note_on(6, note + tp6.value, Math.min(127, Math.floor(127*ap6.amplitude/6000000)))
        onOffset: {
            midiout.note_off(6, noteOnset + tp6.value, 0)
        }
        onPitchbend: {
            midiout.pitchwheel(6, pitchbend)
        }
        onSustain: midiout.aftertouch(6, Math.min(127, Math.floor(127*ap6.amplitude/6000000)))

        Amplitude {
            id: ap6
            input: lid.output
            offset: 128
            channel: 2
        }
    }

    Column {
        z: 100
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 250
        height: 300

        SpinBox {
            id: tp1
            value: 0
        }
        SpinBox {
            id: tp2
            value: 0
        }
        SpinBox {
            id: tp3
            value: 0
        }
        SpinBox {
            id: tp6
            value: 0
        }
    }

    // PitchTracker {
    //     input: rb
    //     threshold: 15000
    //     rate: synth.rate
    //     windowSize: 1024
    // }

    // AudioInputDevice2 {
    //     id: aid
    //     active: true
    //     bufferLength: 1024
    //     rate: 32000
    // }

    // RingBuffer {
    //     id: rb
    //     input: lid.output
    //     length: 32000
    //     channels: 6
    // }

    // RingBuffer {
    //     id: rb2
    //     input: lid.output
    //     length: 1024
    //     channels: 6
    // }

/*
    AudioOutputDevice2 {
        active: true
        bufferLength: 1024
        input: aid.output
        rate: 32000
    }
    */
    RingBuffer {
        id: rb
        input: lid.output
        length: 8000
        channels: 6
    }
/*
    AutoCorrelation {
        id: ac
        input: rb.output
        rate: 32000
        windowSize: 500
    }
*/
    SignalPlotOpenGL {
        anchors.fill: parent
        focus: true
        ValueAxis {
            id: xAxis_
            min: 0
            max: ls2.source.length 
        }

        ValueAxis {
            id: yAxis_
            min: -16384
            max: 16384
        }

        // BufferLineSeries {
        //     id: ls
        //     xAxis: xAxis_
        //     yAxis: yAxis_
        //     color: "orange"
        //     lineWidth: 2
        //     source: amplitudeNode.output
        //     viewChannel: 3
        // }
        BufferLineSeries {
            id: ls2
            xAxis: xAxis_
            yAxis: yAxis_
            color: "red"
            lineWidth: 2
            source: rb.output
            viewChannel: 4
        }
        
        SignalPlotControl {
            id: spc
            anchors.fill: parent
            xAxis: xAxis_
            yAxis: yAxis_
        }

        Keys.onPressed: {
            if(event.key == 74)
                synth.frequency *= Math.pow(2, -1/12)
            if(event.key == 75)
                synth.frequency *= Math.pow(2, 1/12)
            if(event.key == 32)
                rb.running = !rb.running
                // rb2.running = !rb2.running
        }
    }
}
