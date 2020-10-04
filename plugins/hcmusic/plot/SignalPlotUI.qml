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
            model: 11
            property real stride: (yAxis.max - yAxis.min) / (count - 1)
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

            model: 11
            property real stride: (xAxis.max - xAxis.min) / (count - 1)
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
        model: plotUI.model

        delegate: Item {
            id: item
            property alias radius: childRect.radius
            property alias color: childRect.color
            x: (model.px-xAxis.min) / (xAxis.max - xAxis.min) * plotUI.width
            y: plotUI.height - (model.py - yAxis.min) / (yAxis.max - yAxis.min) * plotUI.height
            Rectangle {
                id: childRect
                radius: 3
                x: -radius
                y: -radius
                width: radius*2
                height: radius*2
                color: "black"
                    
                ToolTipHelper {
                    delay: 500
                    onShow: plotUI.toolTip(item, model)
                    onHide: plotUI.hideToolTip()
                }
            }

            Text {
                id: hint
                y: radius*2
                text: model.px.toFixed(1) + "," + model.py.toFixed(1)
            }
            Timer {
                id: tim
                onTriggered: hint.opacity = 0
            }
            onXChanged: {hint.opacity=1; tim.restart()}
            onYChanged: {hint.opacity=1; tim.restart()}
            

        }

    }
}
