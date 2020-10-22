import QtQuick 2.12
import QtQml 2.15
import hcmusic.plot 1.0

/**
 * InteractivePlot
 */
SignalPlotOpenGL {
    id: plot

    clearColor: "#00000000"

    property ValueAxis xAxis: ValueAxis {} ///< X axis of the plot
    property ValueAxis yAxis: ValueAxis {} ///< Y axis of the plot

    property alias mouseCoordX: ctl.mouseCoordX
    property alias mouseCoordY: ctl.mouseCoordY
    property alias mouseAnchor: mouseAnchor_
    property alias recAnchor: recAnchor_
    property alias drawGrid: plotUI.drawGrid
    property alias gridSizeX: plotUI.gridSizeX
    property alias gridSizeY: plotUI.gridSizeY

    property alias rectangleModel: rectangleModel_

    signal selectChanged()

    SignalPlotControl {
        id: ctl
        anchors.fill: parent
        hoverEnabled: true
        xAxis: plot.xAxis
        yAxis: plot.yAxis
        lockView: true

        onPressed: {
            if(lockView) {
                recAnchor_.x1 = mouseCoordX
                recAnchor_.y1 = mouseCoordY
            }
        }

        onReleased: {
            if(lockView) {
                plot.selectChanged()
            }
        }
    }

    ListModel {
        id: pointModel_
    }

    ListModel {
        id: rectangleModel_
    }

    SignalPlotUI {
        id: plotUI
        anchors.fill: parent
        xAxis: plot.xAxis
        yAxis: plot.yAxis

        pointModel: pointModel_
        rectangleModel: rectangleModel_

        PointPlot {
            id: mouseAnchor_
            visible: !ctl.dragging
            px: 0
            py: 0
        }
        
        RectanglePlot {
            id: recAnchor_
            color: "orange"
            opacity: 0.5

            Binding on x2 {
                when: ctl.dragging && ctl.lockView
                value: ctl.mouseCoordX
                restoreMode: Binding.RestoreNone
            }

            Binding on y2 {
                when: ctl.dragging && ctl.lockView
                value: ctl.mouseCoordY
                restoreMode: Binding.RestoreNone
            }

        }
        
    }

    Text {
        text: plot.yAxis.min.toFixed(1)
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "white"
        opacity: ctl.dragging? 1: 0

        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    Text {
        text: plot.yAxis.max.toFixed(1)
        anchors.right: parent.right
        anchors.top: parent.top
        color: "white"
        opacity: ctl.dragging? 1: 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

}

