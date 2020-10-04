import QtQuick 2.12

DataClient {
    id: root
    signal data(real value)
    host: '172.94.78.42:9002'
    type: 'subscribe'
    
    property Connections conn: Connections {
        target: ws
        function onBinaryMessageReceived(message) {
            let arr = new Float32Array(message)
            root.data(arr[0])
        }
    }

}