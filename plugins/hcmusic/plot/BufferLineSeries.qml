import QtQuick 2.12
import hcmusic.dsp 1.0

LineSeries {
    id: root
    property Signal1D source
    property int viewChannel: -1

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
            if(viewChannel === -1)
                return new Float32Array(source.slice(offset, length))
            else
                return new Float32Array(source.sliceChannel(offset, length, viewChannel))
            //return new Float32Array(source.buffer, offset * 4, length)
        } else
            return null
    }
}