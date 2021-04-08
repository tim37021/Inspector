import QtQuick 2.12
import hcmusic.dsp 1.0

LineSeries {
    id: root
    property Signal1D source

    onSourceChanged: {
        if(source)
            this.update(0, source.length)
    }

    Connections {
        target: source
        
        function onUpdate(offset, length) {
            root.update(offset, length)
        }
    }

    function slice(offset, length) {
        if(source) {
            return new Float32Array(source.slice(offset, length))
            //return new Float32Array(source.buffer, offset * 4, length)
        } else
            return null
    }

    function sliceChannel(offset, length, channel) {
        if(source) {
            return new Float32Array(source.sliceChannel(offset, length, channel))
            //return new Float32Array(source.buffer, offset * 4, length)
        } else
            return null
    }

}