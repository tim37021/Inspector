import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    id: root

    width: parent.width * 0.2
    height: parent.height

    property Component content

    property alias color: bg.color 

    Rectangle {
        id: bg
        width: parent.width
        height: parent.height
        x: bm.state === "checked"? 0: -parent.parent.width * 0.2
        Behavior on x {
            NumberAnimation { duration: 100 }
        }
        Loader {
            active: true

            y: bm.y+bm.height+16
            width: parent.width
            height: parent.height - y

            sourceComponent: content
        }
    }

    BurgerMenu {
        id: bm
        x: 16
        y: 16
    }

}
