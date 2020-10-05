import QtQuick 2.12

/*! \brief Point in SignalPlotUI
  *        The object should be placed inside SignalPlotUI
  */
Rectangle {
    id: item

    property real px    /*!< x in signal coordinate */
    property real py    /*!< y in signal coordinate */

    // TODO: xAxis and yAxis binding
    x: (px-xAxis.min) / (xAxis.max - xAxis.min) * parent.width
    y: parent.height - (py - yAxis.min) / (yAxis.max - yAxis.min) * parent.height


    radius: 3
    width: radius*2
    height: radius*2
    color: "black"

    transform: Translate { x: -radius; y: -radius }
        
    ToolTipHelper {
        delay: 200
        onShow: hint.opacity = 1
        onHide: hint.opacity = 0
    }
    

    Text {
        id: hint
        y: radius*2
        text: px.toFixed(1) + "," + py.toFixed(1)
    }
    Timer {
        id: tim
        onTriggered: hint.opacity = 0
    }
    onPxChanged: {hint.opacity=1; tim.restart()}
    onPyChanged: {hint.opacity=1; tim.restart()}
    

}