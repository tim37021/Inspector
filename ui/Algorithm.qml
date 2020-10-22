import QtQuick 2.12

QtObject {
    id: root
    signal incomming()
    signal reset()

    property real startValue: -70
    property real stepValue: 3
    property int threshold: 6
    property QtObject priv: QtObject {
        property real lastValue
        property int stage: 0
        readonly property real checkpoint: startValue + stepValue * stage

        onStageChanged: {
            if(stage == threshold)
                root.incomming()
            
            console.log([stage, threshold, startValue])
        }

    }


    function feed(val) {
        if(priv.lastValue < priv.checkpoint && val >= priv.checkpoint) {
            priv.stage++
            tim.stop()
        }
        priv.lastValue = val

        if(priv.lastValue < startValue) {
            tim.start()
        } else
            tim.stop()
        
    }

    property Timer tim: Timer {
        interval: 500
        onTriggered: {
            init()
        }
    }

    function init() {
        priv.stage = 0
        root.reset()
    }
    
}