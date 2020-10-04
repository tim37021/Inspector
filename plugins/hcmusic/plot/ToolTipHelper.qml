import QtQuick 2.12

MouseArea {
    id: root
    signal show
    signal hide
    
    anchors.fill: parent
    hoverEnabled: true

    property alias delay: tim.interval


    onPressed: mouse.accepted = false
    onReleased: mouse.accepted = false
    onPositionChanged: mouse.accepted = false

    onContainsMouseChanged: {
        tim.restart()
    }
    Timer {
        id: tim
        onTriggered: {
            if(containsMouse)
                root.show()
            else
                root.hide()
        }
    }
}