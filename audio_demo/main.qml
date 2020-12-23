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

    AudioInputDevice2 {
        id: aid
        active: true
        bufferLength: 1024
        rate: 32000
    }

    RingBuffer {
        id: rb
        input: aid.output
        length: 32000
        channels: 1
    }

    AudioOutputDevice2 {
        active: true
        bufferLength: 1024
        input: aid.output
        rate: 32000
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
            source: rb.output
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
        }
    }
}
