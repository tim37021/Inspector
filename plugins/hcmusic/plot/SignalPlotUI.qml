import QtQuick 2.12

Item {
    signal toolTip(var obj, var model)
    signal hideToolTip()

    id: plotUI
    property ValueAxis xAxis
    property ValueAxis yAxis

    property ListModel pointModel           ///< point model in format {px: number, py: number}
    property ListModel rectangleModel       ///< rectangle model in format {x1: number, y1: number, x2: number, y2: number}

    property bool drawGrid: true
    property real gridSizeX: 200
    property real gridSizeY: 20

    clip: true

    Loader {
        id: grid
        anchors.fill: parent
        opacity: plotUI.drawGrid? 1: 0
        Behavior on opacity {
            NumberAnimation { duration: 100 }
        }
        active: true

        sourceComponent: drawGrid? gridComp: null
    }

    Repeater {
        anchors.fill: parent
        model: plotUI.pointModel

        delegate: PointPlot {
            px: model.px
            py: model.py
        }
    }

    Repeater {
        anchors.fill: parent
        model: plotUI.rectangleModel

        delegate: RectanglePlot {
            x1: model.x1
            y1: model.y1

            x2: model.x2
            y2: model.y2

            text: model.text
        }
    }

    Component {
        id: gridComp
        Item {
            Repeater {
                id: repy
                model: Math.ceil((yAxis.max - yAxis.min) / stride) + 1
                property real stride: gridSizeY
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
                property real stride: gridSizeX
                property real startX: Math.floor(xAxis.min / stride) * stride
                delegate: Rectangle {
                    
                    x: (repx.startX+model.index*repx.stride-xAxis.min) / (xAxis.max - xAxis.min) * plotUI.width
                    width: 1
                    height: parent.height
                    opacity: 0.1
                }
            }
        }

    }
}
