import QtQuick 2.12

QtObject {
    property var array: new Array(1).fill(0)
    signal update(var array)

    function set(arr) {
        array = arr
        this.update(array)
    }
}