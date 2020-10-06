import QtQuick 2.12

ListModel {
    id: root
    property real timeout: 1000
    property real removeTimeout: 5000

    readonly property QtObject priv: QtObject {
        property var data: ({});
        property var index: [];
    }

    property Timer tim: Timer {
        interval: timeout
        repeat: true
        running: timeout != 0
        onTriggered: {
            let now = Date.now()
            let rm = 0
            let rem = []


            for(let i=0; i<priv.index.length; i++) {
                let elapsedTime = now - priv.data[priv.index[i]].timestamp
                if(elapsedTime >= timeout) {
                    root.set(i, {active: false});
                }
                if(elapsedTime >= removeTimeout) {
                    root.remove(i-rm)
                    rm++;
                } else
                    rem.push(priv.index[i])
            }

            priv.index = rem
        }
    }

    function update(addr, rssi) {
        let v;
        if(priv.index.indexOf(addr)!==-1) {
            v = priv.data[addr];
            v.rssi = rssi;
            v.timestamp = Date.now()

            let idx = priv.index.indexOf(addr);
            root.set(idx, {rssi: rssi, active: true});
        } else {
            v = priv.data[addr] = {rssi: rssi, timestamp: Date.now()};
            priv.index.push(addr);

            root.append({addr: addr, rssi: rssi, active: true});
        }


    }

}
