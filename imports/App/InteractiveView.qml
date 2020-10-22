import QtQuick 2.12

Item {
    id: ctl

    property real mouseX
    property real mouseY

    property Component content
    property Component background: Rectangle {
        anchors.fill: parent
    }

    Loader {
        id: loader
        active: true
        anchors.centerIn: parent
        sourceComponent: content

        onLoaded: {
            this.item.transform.push(ts)
            this.item.transform.push(tf)
        }
    }



    property Translate tf: Translate {}
    property Scale ts: Scale {
        xScale: 1
        yScale: 1
    }


    MouseArea {
        id: ma
        anchors.fill: parent
        cursorShape: containsPress? Qt.OpenHandCursor: Qt.ArrowCursor
        property real dragStartX
        property real dragStartY

        onPressed: {
            dragStartX = mouse.x
            dragStartY = mouse.y

        }

        onPositionChanged: {
            if(pressed) {
                if(pressedButtons === Qt.LeftButton) {
                    tf.x += mouse.x - dragStartX
                    tf.y += mouse.y - dragStartY
                }
                dragStartX = mouse.x
                dragStartY = mouse.y
            }
        }
        onWheel: {
            
            ts.xScale += (wheel.angleDelta.y>0? 0.1: -0.1)
            ts.yScale += (wheel.angleDelta.y>0? 0.1: -0.1)
            
        }
    }
}