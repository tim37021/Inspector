import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    id: root

    property alias value: switchButton.checked

    Row {
        spacing: 8
        Text {
            text: "關"
            color: "white"
            font.pointSize: 12
            font.family: "Microsoft JhengHei"
        }
        Switch {
            id: switchButton
        }
        Text {
            text: "開"
            color: "white"
            font.pointSize: 12
            font.family: "Microsoft JhengHei"
        }
    }

    
}