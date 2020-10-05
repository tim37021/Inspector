import QtQuick 2.12

/*! \brief Point in SignalPlotUI
  *        The object should be placed inside SignalPlotUI
  */
Item {
    id: item
    property alias radius: childRect.radius /*!< radius of the point */
    property alias color: childRect.color   /*!< color */

    property real px    /*!< x in signal coordinate */
    property real py    /*!< y in signal coordinate */

    // TODO: xAxis and yAxis binding
    x: (px-xAxis.min) / (xAxis.max - xAxis.min) * parent.width
    y: parent.height - (py - yAxis.min) / (yAxis.max - yAxis.min) * parent.height
    Rectangle {
        id: childRect
        radius: 3
        x: -radius
        y: -radius
        width: radius*2
        height: radius*2
        color: "black"
            
        ToolTipHelper {
            delay: 200
            onShow: hint.opacity = 1
            onHide: hint.opacity = 0
        }
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