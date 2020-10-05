import QtQuick 2.12

Item {
    signal toolTip(var obj, var model)
    signal hideToolTip()

    id: plotUI
    property ValueAxis xAxis
    property ValueAxis yAxis
    property ListModel model

    property bool drawGrid: true

    clip: true

    Item {
        id: grid
        anchors.fill: parent
        opacity: plotUI.drawGrid? 1: 0
        Behavior on opacity {
            NumberAnimation { duration: 100 }
        }
        Repeater {
            id: repy
            model: Math.ceil((yAxis.max - yAxis.min) / stride) + 1
            property real stride: 20
            property real startY: Math.floor(yAxis.min / stride) * stride
            delegate: Rectangle {
                y: plotUI.height - (repy.startY+model.index*repy.stride - yAxis.min) / (yAxis.max - yAxis.min) * plotUI.height
                width: parent.width
                height: 1
                opacity: 0.1
            }
        }

        Repeater {
            id: repx

            model: Math.ceil((xAxis.max - xAxis.min) / stride) + 1
            property real stride: 200
            property real startX: Math.floor(xAxis.min / stride) * stride
            delegate: Rectangle {
                
                x: (repx.startX+model.index*repx.stride-xAxis.min) / (xAxis.max - xAxis.min) * plotUI.width
                width: 1
                height: parent.height
                opacity: 0.1
            }
        }
    }

    Repeater {
        anchors.fill: parent
        model: plotUI.model

        delegate: Point {
            px: model.px
            py: model.py
        }

    }
}
