import QtQuick 2.12
import hcmusic.plot 1.0

/**
 * InteractivePlot
 */
SignalPlotOpenGL {
    id: plot

    clearColor: "#00000000"

    property ValueAxis xAxis: ValueAxis {} ///< X axis of the plot
    property ValueAxis yAxis: ValueAxis {} ///< Y axis of the plot

    SignalPlotControl {
        id: ctl
        anchors.fill: parent
        hoverEnabled: true
        xAxis: plot.xAxis
        yAxis: plot.yAxis
    }

    ListModel {
        id: ui
        ListElement { px: 100; py: 100}
    }

    SignalPlotUI {
        anchors.fill: parent
        xAxis: plot.xAxis
        yAxis: plot.yAxis

        model: ui
        
        drawGrid: ctl.dragging
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

