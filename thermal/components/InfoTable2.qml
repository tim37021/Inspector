import QtQuick 2.12
import QtQuick.Controls 2.12

import ".."

Item {
    id: root
    property alias model: ls.model
    property var headerNames: ["Trace", "Value(1)", "Value(2)", "Value Diff"]
    property var headerDisplay
    property string borderColor: "#1D1D1D"

    property string fontColor: "white"
    property string fontFamily: "Roboto"
    property string headerColor: "#171717"
    property string contentColor: "#1A1A1A"
    property bool readOnly: true

    signal edited(int index, int column, var value)

    AppMaterial { id: appMaterial }

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
            color: root.headerColor
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
                        color: root.fontColor
                        font.family: root.fontFamily
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
                        color: root.fontColor
                        font.family: root.fontFamily
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
                        color: root.fontColor
                        font.family: root.fontFamily
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
                        color: root.fontColor
                        font.family: root.fontFamily
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

                    TextInput {
                        anchors.centerIn: parent
                        text: root.model[index]["name"]
                        color: root.fontColor
                        font.family: root.fontFamily
                        readOnly: true
                        selectByMouse: true
                        onEditingFinished: root.edited()
                    }
                }

                Rectangle {
                    width: root.width * 0.25
                    height: parent.height
                    color: "transparent"
                    border.color: root.borderColor
                    border.width: 1

                    TextInput {
                        anchors.centerIn: parent
                        text: root.model[index]["v1"]
                        color: root.fontColor
                        font.family: root.fontFamily
                        readOnly: root.readOnly
                        selectByMouse: true
                        onEditingFinished: root.edited(index, 1, text)
                    }
                }

                Rectangle {
                    width: root.width * 0.25
                    height: parent.height
                    color: "transparent"
                    border.color: root.borderColor
                    border.width: 1

                    TextInput {
                        anchors.centerIn: parent
                        text: root.model[index]["v2"]
                        color: root.fontColor
                        font.family: root.fontFamily
                        readOnly: root.readOnly
                        selectByMouse: true
                        onEditingFinished: root.edited(index, 2, text)
                    }
                }

                Rectangle {
                    width: root.width * 0.25
                    height: parent.height
                    color: "transparent"
                    border.color: root.borderColor
                    border.width: 1

                    TextInput {
                        anchors.centerIn: parent
                        text: root.model[index]["v3"]
                        color: root.fontColor
                        font.family: root.fontFamily
                        readOnly: true
                        selectByMouse: true
                        onEditingFinished: root.edited()
                    }
                }
            }
        }
        
    }

}