import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    id: root
    property alias model: ls.model
    property var headerNames: ["Trace", "Value(1)", "Value(2)", "Value Diff"]
    property var headerDisplay
    property string borderColor: "#1D1D1D"

    ListView {
        id: ls
        anchors.fill: parent
        header: lsHeader
        delegate: comp

        headerPositioning: ListView.OverlayHeader
        clip: true
    }

    Component {
        id: lsHeader
        Rectangle {
            width: root.width
            height: 30
            color: "#DDDDDD"
            z: 2

            Row {
                anchors.fill: parent

                Rectangle {
                    width: root.width * 0.25
                    height: parent.height
                    color: "transparent"
                    border.color: root.borderColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.headerNames[0]
                    }
                }

                Rectangle {
                    width: root.width * 0.25
                    height: parent.height
                    color: "transparent"
                    border.color: root.borderColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.headerNames[1]
                    }
                }

                Rectangle {
                    width: root.width * 0.25
                    height: parent.height
                    color: "transparent"
                    border.color: root.borderColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.headerNames[2]
                    }
                }

                Rectangle {
                    width: root.width * 0.25
                    height: parent.height
                    color: "transparent"
                    border.color: root.borderColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.headerNames[3]
                    }
                }
            }
        }
    }

    Component {
        id: comp
        Item {
            width: root.width
            height: 30

            Row {
                anchors.fill: parent

                Rectangle {
                    width: root.width * 0.25
                    height: parent.height
                    color: "transparent"
                    border.color: root.borderColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.model[index]["name"]
                    }
                }

                Rectangle {
                    width: root.width * 0.25
                    height: parent.height
                    color: "transparent"
                    border.color: root.borderColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.model[index]["v1"]
                    }
                }

                Rectangle {
                    width: root.width * 0.25
                    height: parent.height
                    color: "transparent"
                    border.color: root.borderColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.model[index]["v2"]
                    }
                }

                Rectangle {
                    width: root.width * 0.25
                    height: parent.height
                    color: "transparent"
                    border.color: root.borderColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.model[index]["v3"]
                    }
                }
            }
        }
        
    }

}