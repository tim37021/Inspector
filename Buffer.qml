import QtQuick 2.12

QtObject {
    property var array
    signal update(var array)

    function set(arr) {
        array = arr
        this.update(array)
    }
}