
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.1
import App 1.0
// import hcmusic.audio 1.0
import hcmusic.plot 1.0
import hcmusic.dsp 1.0
import hcmusic.licap 1.0
import hcmusic.midi 1.0
import hcmusic.loader 1.0

ApplicationWindow {
    width: 800
    height: 600
    visible: true
    color: "black"
    title: 'NegativeGrid' + `${spc.mouseCoordX}${spc.mouseCoordY}`

    // Image {
    //     anchors.centerIn: parent
    //     source: 'logo.png'
    // }

    // LiCAPv1 {
    //     id: lid
    //     active: true
    //     port: 'COM4'
    //     //  0-x 1-3s 2-6s 3-x 4-2s 5-1s
    //     // channels: [5]
    //     bufferLength: 1024
    //     onError: {
    //         console.log(message)
    //     }
    // }

    // MidiDiscoveryModelProvider{
    //     id: midiP
    // }

    // MidiOutputDevice {
    //     id:midiout
    //     portName: midiP.find("LiCAP")
    // }

    // SineSynth {
    //     id: synth
    //     rate: 32000
    //     frequency: 440
    //     length: 256
    //     amplitude: 2000
    //     Timer {
    //         running: false
    //         repeat: true
    //         interval: parent.frequency / 32000 * 1000 
    //         onTriggered: synth.synth()
    //     }
    // }

    PitchTracker {
        id: pt1
        input: lid.output
        rate: 32000
        channel: 5

        onOnset: midiout.note_on(1, note + tp1.value,  Math.min(127, Math.floor(127*ap1.amplitude/2000000)))
        onOffset: {
            midiout.note_off(1, noteOnset + tp1.value, 0)
        }
        onSustain: midiout.aftertouch(1, Math.min(127, Math.floor(127*ap1.amplitude/2000000)))

        Amplitude {
            id: ap1
            input: lid.output
            offset: 128
            channel: 5
        }
    }

    CsvLoader { id: csv }

    // FileDialog {
    //     id: ofd
    //     nameFilters: [ "csv files (*.csv)" ]
    //     selectExisting: false
    //     onAccepted: {
    //         csv.filename = fileUrl
    //         // windowing.focusedWindow.signalSource.saveToFile(fileUrl)
    //     }
    // }

    FileDialog {
        id: ofd
        nameFilters: [ "csv files (*.csv)" ]
        onAccepted: {
            // let win = app.createQuickPlotWindow('plot')
            // let buf = buf_comp.createObject(null, {filename: fileUrl})
            // win.node = buf
            csv.filename = fileUrl
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
    /*
    RingBuffer {
        id: rb
        input: lid.output
        length: 1024
        channels: 1
    }*/
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
            source: csv.output
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
            // if(event.key == 32)

            //     rb.running = !rb.running
            //     rb2.running = !rb2.running
        }
    }

    SideBar {
        id: sb
        color: Constants.foreground1
        content: Column {
            anchors.fill: parent
            spacing: 16
            
            SideButton {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.8
                height: 48
                text: '+'
                onClicked: contextMenu.open()
                
                Menu {
                    id: contextMenu
                    x: parent.width / 2
                    y: parent.height
                    MenuItem {
                        text: "Open Files (*.csv)"
                        onClicked: ofd.open()
                    }
                }
            }
        }
    }
}
