import QtQuick 2.12
import inspector.dsp 1.0

LineSeries {
    id: root
    property SignalOutput source

    Connections {
        target: source
        
        function onUpdate(offset, length) {
            root.update(offset, length)
        }
    }

    function slice(offset, length) {
        if(source) {
            return new Float32Array(source.buffer, offset * 4, length)
        } else
            return null

    }

}