import QtQuick 2.0

Item {
    signal update(var array)

    //TODO: array and length is not tight together
    property var array: new Array(4096).fill(0)
    property int length: 0
    property real lineWidth: 2
    property color color: "black"
    //property bool visible: true

    property ValueAxis xAxis: ValueAxis {
        min: -100
        max: 100
    }

    property ValueAxis yAxis: ValueAxis {
        min: -100
        max: 100
    }

    onLengthChanged: array = new Array(length).fill(0)

    function append(b) {
        // TODO: typecheck sould be done somewhere else!!!!
        if(!Array.isArray(array)) {
            console.log('array property currently is not an javascript array')
            return
        }
        array = array.slice(1)
        array.push(b)

        this.update(array)
    }

    function init() {
        array = new Array(length).fill(0)
        this.update(array)
    }

    function set(arr) {
        length = arr.length
        array = arr
        this.update(arr)
    }
}
