import QtQuick 2.12
import QtQuick.Controls 2.12
import Qt.labs.qmlmodels 1.0

Item {
    id: root
    property alias model: infoTable.model

    TableView {
        id: infoTable
        anchors.fill: parent
        boundsBehavior: Flickable.StopAtBounds

        model: TableModel {
            TableModelColumn { display: "trace"}
            TableModelColumn { display: "value1"}
            TableModelColumn { display: "value2"}
            TableModelColumn { display: "diff"}

            rows: [
                {
                    trace: { color: "red", display: "CH1[V]"},
                    value1: "-151.50",
                    value2: "-83.500",
                    diff: "68.00"
                },
                {
                    trace: { color: "blue", display: "CH2[V]"},
                    value1: "-151.50",
                    value2: "-83.500",
                    diff: "68.00"
                },
                {
                    trace: { color: "green", display: "CH3[V]"},
                    value1: "-151.50",
                    value2: "-83.500",
                    diff: "68.00"
                },
                {
                    trace: { color: "red", display: "CH1[V]"},
                    value1: "-151.50",
                    value2: "-83.500",
                    diff: "68.00"
                },
                {
                    trace: { color: "red", display: "CH1[V]"},
                    value1: "-151.50",
                    value2: "-83.500",
                    diff: "68.00"
                },
            ]
        }

        delegate: DelegateChooser {
            DelegateChoice {
                column: 0
                delegate: Rectangle {
                    color: "white"
                    implicitWidth: infoTable.width * 0.25
                    implicitHeight: 40
                    border.width: 1
                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 3
                        spacing: 3
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 5; height: 12;
                            color: model.display.color
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.display.display
                        }
                    }
                }
            }
            DelegateChoice {
                delegate: Rectangle {
                    implicitWidth: infoTable.width * 0.25
                    implicitHeight: 40
                    color: "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: model.display

                    }
                }
            }
        }
    }
}