import QtQuick 2.12

QtObject {
    id: bv
    signal update(var array)
    property var sourceBuffer
    property var channel: 0
    readonly property int channels: sourceBuffer.channels
    property var array: (new Float32Array(sourceBuffer.array, channel * sourceBuffer.length * 4, length))
    property int length: sourceBuffer.length
    property bool recording: true
    readonly property real rate: sourceBuffer.rate

    property Connections conn: Connections {
        target: sourceBuffer
        function onUpdate(array) {
            if(recording)
                bv.update(bv.array)
        }
    }

    onRecordingChanged: {
        // propagate back to source(IMPORTANT)
        // other wrapped buffer is still changing
        sourceBuffer.recording = recording
    }

    onArrayChanged: {
        bv.update(array)
    }

}