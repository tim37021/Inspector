import QtQuick 2.12

QtObject {
    id: root
    signal incomming()
    signal reset()
    property QtObject priv: QtObject {
        property real lastValue
        property real stage: 0
        readonly property real checkpoint: -70 + 5 * stage

        onStageChanged: if(stage == 4) root.incomming()

    }


    function feed(val) {
        if(priv.lastValue < priv.checkpoint && val >= priv.checkpoint) {
            priv.stage++
            tim.restart()
        }
        priv.lastValue = val

        if(priv.lastValue < -70) {
            tim.start()
        }
        
    }

    property Timer tim: Timer {
        interval: 2000
        onTriggered: {
            init()
        }
    }

    function init() {
        priv.stage = 0
        root.reset()
    }
    
}