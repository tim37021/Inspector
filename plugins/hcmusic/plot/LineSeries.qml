import QtQuick 2.0

Item {
    signal update(int offset, int length)

    property real lineWidth: 2
    property color color: "black"
    //property bool visible: true
    property int length;

    property ValueAxis xAxis: ValueAxis {
        min: -100
        max: 100
    }

    property ValueAxis yAxis: ValueAxis {
        min: -100
        max: 100
    }

    function slice(offset, length) {

    }
}
