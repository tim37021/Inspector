import QtQuick 2.12
import App 1.0

QtObject {
    id: filter1

    property bool applyMedian: true
    property bool applyKalman: true

    property int kernelSize: 7
    property var buff: new Array(7).fill(0);


    property real r: 0.05
    property real q: 2
    property var filter: new Kalman.KalmanFilter({R: r, Q: q});
    
    onKernelSizeChanged: {
        if(kernelSize % 2 == 0)
            kernelSize++
        else
            buff = new Array(kernelSize).fill(0)

    }


    function f(rssi) {
        buff = buff.slice(1)
        buff.push(rssi)
        let tmp = [...buff].sort()
        let filteredRSSI = rssi

        if(applyMedian)
            filteredRSSI = tmp[Math.floor(kernelSize/2)]

        if(applyKalman)
            filteredRSSI = filter.filter(filteredRSSI)


        return filteredRSSI
    }

    function init() {
        buff = new Array(buff.length).fill(0)
        filter = new Kalman.KalmanFilter({R:r, Q: q})
    }
}