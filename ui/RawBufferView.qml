import QtQuick 2.12

QtObject {
    id: bv
    signal update(var array)
    property var sourceBuffer
    property var channel: 0
    readonly property int channels: sourceBuffer.channels
    property var array: (new Float32Array(sourceBuffer.array, channel * sourceBuffer.length * 4, length))
    property int length: sourceBuffer.length

    property Connections conn: Connections {
        target: sourceBuffer
        function onUpdate(array) {
            bv.update(bv.array)
        }
    }

    onArrayChanged: {
        bv.update(array)
    }

}