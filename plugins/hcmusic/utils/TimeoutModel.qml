import QtQuick 2.12

ListModel {
    id: root

    property real timeout: 4000
    property real grayout: timeout - 1000

    readonly property QtObject priv: QtObject {
        property var metaData: ({});
        property var keys: [];
    }

    property Timer tim: Timer {
        interval: 100
        repeat: true
        running: timeout != 0
        onTriggered: {
            let now = Date.now()
            let rm = 0
            let rem = []

            for(let i=0; i<priv.keys.length; i++) {
                let elapsedTime = now - priv.metaData[priv.keys[i]].timestamp
                
                if(elapsedTime >= timeout) {
                    root.remove(i-rm)
                    rm++;
                } else if(elapsedTime >= grayout) {
                    root.set(i-rm, {active: false});
                    rem.push(priv.keys[i])
                } else
                    rem.push(priv.keys[i])
            }

            priv.keys = rem
        }
    }

    function update(key, modelData, userData) {
        let v;
        if(priv.keys.indexOf(key)!=-1) {
            v = priv.metaData[key];
            
            v.timestamp = Date.now()
            v.userData = undefined
            if(userData)
                v.userData = userData

            let idx = priv.keys.indexOf(key);
            modelData['active'] = true
            root.set(idx, modelData);
        } else {
            v = priv.metaData[key] = {userData: userData, timestamp: Date.now()};
            priv.keys.push(key);
            modelData['active'] = true
            root.append(modelData);
        }
    }

}
