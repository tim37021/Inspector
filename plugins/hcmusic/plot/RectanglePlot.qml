import QtQuick 2.12

/*! \brief Rectangle in SignalPlotUI
  *        The object should be placed inside SignalPlotUI
  */
Rectangle {

    property real x1    /*!< x1 in signal coordinate */
    property real y1    /*!< y1 in signal coordinate */

    property real x2    /*!< x2 in signal coordinate */
    property real y2    /*!< y2 in signal coordinate */

    property alias text: hint.text

    // TODO: xAxis and yAxis binding
    x: (Math.min(x1, x2)-xAxis.min) / (xAxis.max - xAxis.min) * parent.width
    y: parent.height - (Math.min(y1, y2) - yAxis.min) / (yAxis.max - yAxis.min) * parent.height

    width: Math.abs(x1 - x2) / (xAxis.max - xAxis.min) * parent.width
    height: Math.abs(y1 - y2) / (yAxis.max - yAxis.min) * parent.height

    Text {
        id: hint
        anchors.centerIn: parent
    }
    Timer {
        id: tim
        onTriggered: hint.opacity = 0
    }
    onX1Changed: {hint.opacity=1; tim.restart()}
    onY1Changed: {hint.opacity=1; tim.restart()}
    

}