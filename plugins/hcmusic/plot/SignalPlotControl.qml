import QtQuick 2.12

Item {
    id: plotControl
    signal pressed(var mouse)
    signal released(var mouse)

    property ValueAxis xAxis: ValueAxis {}
    property ValueAxis yAxis: ValueAxis {}

    property alias mouseX: ma.mouseX
    property alias mouseY: ma.mouseY

    property real mouseCoordX: mouseX / width * (xAxis.max - xAxis.min) + xAxis.min
    property real mouseCoordY: (mouseY - height) / height * -(yAxis.max - yAxis.min) + yAxis.min
    property alias dragging: ma.containsPress

    property alias hoverEnabled: ma.hoverEnabled

    property bool lockView: false
    property bool lockX: false
    property bool lockY: false

    property bool lockScrollX: false
    property bool lockScrollY: false
    property bool lockZoomX: false
    property bool lockZoomY: false

    QtObject {
        id: priv
        property real dragStartX
        property real dragStartY
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        Keys.forwardTo: [parent]

        onPressed: {
            lockView = (mouse.modifiers & Qt.ShiftModifier)
            priv.dragStartX = mouse.x
            priv.dragStartY = mouse.y

            focus = true

            // forward this signal
            plotControl.pressed(mouse)
        }

        onReleased: {
            // forward this signal
            plotControl.released(mouse)
        }

        onWheel: {
            let dir = wheel.angleDelta.y>0? -1: 1
            let scale = (1+dir*0.1)
            if(!lockX) {
                xAxis.min = (xAxis.min - mouseCoordX) * scale + mouseCoordX
                xAxis.max = (xAxis.max - mouseCoordX) * scale + mouseCoordX
            }
            if(!lockY) {
                yAxis.min = (yAxis.min - mouseCoordY) * scale + mouseCoordY
                yAxis.max = (yAxis.max - mouseCoordY) * scale + mouseCoordY
            }
        }

        onPositionChanged: {
            if(pressed && !lockView) {
                // map from screen coordinate to signal coordinate
                let xy1 = map_coord(priv.dragStartX, priv.dragStartY)
                priv.dragStartX = mouse.x; priv.dragStartY = mouse.y;

                // calculate delta in signal coordinate
                let dx = mouseCoordX - xy1[0]
                let dy = mouseCoordY - xy1[1]

                if(pressedButtons === Qt.LeftButton) {
                    // dragging
                    if(!lockScrollX) { xAxis.min -= dx; xAxis.max -= dx;}
                    if(!lockScrollY) { yAxis.min -= dy; yAxis.max -= dy; }
                } else if(pressedButtons === Qt.RightButton){
                    // zooming
                    if(!lockZoomX) { xAxis.min += dx; xAxis.max -= dx; }
                    if(!lockZoomY) { yAxis.min += dy; yAxis.max -= dy; }
                }

            }
        }
    }

    function map_coord(x, y) {
        x = x / width * (xAxis.max - xAxis.min) + xAxis.min
        y = (y - height) / height * -(yAxis.max - yAxis.min) + yAxis.min

        return [x, y]
    }

    states: [
        State {
            name: ''
            when: !dragging
            PropertyChanges { target: ma; cursorShape: Qt.ArrowCursor }
        },
        State {
            name: 'dragging'
            when: dragging && !lockView
            PropertyChanges { target: ma; cursorShape: Qt.OpenHandCursor }
        },
        State {
            name: 'selecting'
            when: dragging && lockView
            PropertyChanges { target: ma; cursorShape: Qt.CrossCursor }
        }
    ]
}
