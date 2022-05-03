import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    id: root

    property alias value: spinBox.value
    property alias from: spinBox.from
    property alias to: spinBox.to


    SpinBox {
        id: spinBox
        width: root.width
        height: root.height

        from: -10000
        to: 10000
        editable: true
    }
}