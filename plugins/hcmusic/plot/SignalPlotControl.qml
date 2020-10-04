import QtQuick 2.12

Item {
    property ValueAxis xAxis: ValueAxis {}
    property ValueAxis yAxis: ValueAxis {}

    property alias mouseX: ma.mouseX
    property alias mouseY: ma.mouseY

    property real mouseCoordX: mouseX / width * (xAxis.max - xAxis.min) + xAxis.min
    property real mouseCoordY: (mouseY - height) / height * -(yAxis.max - yAxis.min) + yAxis.min
    property alias dragging: ma.containsPress

    property alias hoverEnabled: ma.hoverEnabled

    QtObject {
        id: priv
        property real dragStartX
        property real dragStartY

    }

    MouseArea {
        id: ma
        anchors.fill: parent
        cursorShape: containsPress? Qt.OpenHandCursor: Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        Keys.forwardTo: [parent]
        
        onPressed: {
            priv.dragStartX = mouse.x
            priv.dragStartY = mouse.y

            focus = true
        }

        onPositionChanged: {
            if(pressed) {
                // map from screen coordinate to signal coordinate
                let xy1 = map_coord(priv.dragStartX, priv.dragStartY)
                priv.dragStartX = mouse.x; priv.dragStartY = mouse.y;

                // calculate delta in signal coordinate
                let dx = mouseCoordX - xy1[0]
                let dy = mouseCoordY - xy1[1]

                if(pressedButtons === Qt.LeftButton) {
                    // dragging
                    xAxis.min -= dx; xAxis.max -= dx;
                    yAxis.min -= dy; yAxis.max -= dy;
                } else if(pressedButtons === Qt.RightButton){
                    // zooming
                    xAxis.min += dx; xAxis.max -= dx;
                    yAxis.min += dy; yAxis.max -= dy;
                }

            }
        }
    }

    function map_coord(x, y) {
        x = x / width * (xAxis.max - xAxis.min) + xAxis.min
        y = (y - height) / height * -(yAxis.max - yAxis.min) + yAxis.min

        return [x, y]
    }
}
