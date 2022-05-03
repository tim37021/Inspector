import QtQuick 2.12
import QtQml 2.15
import QtQuick.Controls 2.14
import Qt.labs.platform 1.1
import App 1.0

import hcmusic.plot 1.0
import hcmusic.dsp 1.0

import ".."
import "inputBox"

Rectangle {
    id: root
    property alias windowColor: window.color
    property ThermalReportNode reporter: ThermalReportNode{}
    property string standard: "VDE"

    color: "#A5222222"
    opacity: 0.0
    Behavior on opacity { NumberAnimation { duration: 100 } }
    visible: root.opacity > 0.0

    AppMaterial { id: appMaterial }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.close()
        }
    }

    Rectangle {
        id: window
        anchors.centerIn: parent
        color: appMaterial.surface4

        width: parent.width * 0.9
        height: parent.height * 0.9
        radius: 10

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: false
            preventStealing: true
        }

        ScrollView {
            anchors.fill: parent
            clip: true
            Column {
                anchors.fill: parent
                anchors.margins: 30

                Column {
                    width: parent.width
                    height: childrenRect.height + 20
                    spacing: 20
                    Text {
                        text: "Standard"
                        font.pixelSize: 18
                        color: "white"
                    }
                    Row {
                        id: standardSetting
                        width: parent.width
                        anchors.topMargin: 20
                        anchors.leftMargin: 20
                        height: childrenRect.height
                        spacing: 80

                        ButtonGroup { id: standardRadioGroup }

                        Column {
                            spacing: 20
                            Text {
                                x: 10
                                text: "LV network"
                                font.pixelSize: 16
                                color: "white"
                            }
                            Row {
                                RadioButton {
                                    id: vdeChecked
                                    checked: true
                                    ButtonGroup.group: standardRadioGroup
                                    onCheckedChanged: root.standard = "VDE"
                                }

                                Text {
                                    text: "VDE V 0124-100:2020,\nVDE-AR-N 4105:2018"
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: "white"
                                }
                            }
                            
                            Row {
                                RadioButton {
                                    id: enChecked
                                    checked: true
                                    ButtonGroup.group: standardRadioGroup
                                    onCheckedChanged: root.standard = "VDE"
                                }

                                Text {
                                    text: "EN 50549-1:2019"
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: "white"
                                }
                            }
                        }

                        Column {
                            spacing: 20
                            Text {
                                x: 10
                                text: "MV network"
                                font.pixelSize: 16
                                color: "white"
                            }
                            Row {
                                RadioButton {
                                    id: bdewChecked
                                    checked: true
                                    ButtonGroup.group: standardRadioGroup
                                    onCheckedChanged: root.standard = "BDEW"
                                }

                                Text {
                                    text: "BDEW TG3 Ver.25"
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: "white"
                                }

                            }
                            Row {
                                RadioButton {
                                    id: vde4110Checked
                                    checked: true
                                    ButtonGroup.group: standardRadioGroup
                                    onCheckedChanged: root.standard = "BDEW"
                                }

                                Text {
                                    text: "VDE-AR-N 4110:2018"
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: "white"
                                }
                            }
                            
                            
                            Row {
                                RadioButton {
                                    id: vde4120Checked
                                    checked: true
                                    ButtonGroup.group: standardRadioGroup
                                    onCheckedChanged: root.standard = "BDEW"
                                }

                                Text {
                                    text: "VDE-AR-N 4120:2018, EN"
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: "white"
                                }
                            }
                        }
                    }
                }
                
                Column {
                    width: parent.width
                    height: childrenRect.height + 20
                    spacing: 20
                    Text {
                        width: 100
                        text: "Test Information"
                        font.pixelSize: 18
                        color: "white"
                    } 

                    Row {
                        spacing: 20
                        Text {
                            text: "Test Number"
                            color: "white"
                        }

                        Rectangle {
                            width: 100
                            height: 30
                            anchors.verticalCenter: parent.verticalCenter;
                            color: "white"

                            TextInput {
                                id: testNumber
                                text: "0"
                                anchors.verticalCenter: parent.verticalCenter;
                                anchors.left: parent.left;anchors.right: parent.right;
                                anchors.margins: 5
                            }
                        }
                    }

                    Column {
                        spacing: 20
                        Text {
                            width: 100
                            text: "Test Condition"
                            color: "white"
                            font.pixelSize: 16
                        }

                        Row {
                            spacing: 20
                            Text {
                                width: 100
                                anchors.verticalCenter: parent.verticalCenter;
                                text: "Qstart"
                                color: "white"
                            }

                            IntInputBox {
                                id: qstartValue
                                width: 150
                                height: 30
                                anchors.verticalCenter: parent.verticalCenter;
                                
                                from: -100
                                to: 200000
                                value: 0
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter;
                                text: "p.u."
                                color: "white"
                            }
                        }

                        Row {
                            spacing: 20
                            Text {
                                width: 100
                                anchors.verticalCenter: parent.verticalCenter;
                                text: "Qsoll"
                                color: "white"
                            }

                            IntInputBox {
                                id: qsollValue
                                width: 150
                                height: 30
                                anchors.verticalCenter: parent.verticalCenter;
                                
                                from: -100
                                to: 200000
                                value: 100
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter;
                                text: "p.u."
                                color: "white"
                            }
                        }

                        Row {
                            spacing: 20
                            Text {
                                width: 100
                                anchors.verticalCenter: parent.verticalCenter;
                                text: "KRR"
                                color: "white"
                            }

                            FloatInputBox {
                                id: krrValue
                                width: 150
                                height: 30
                                anchors.verticalCenter: parent.verticalCenter;
                                
                                from: 1
                                to: 5
                                value: 4.92
                                stepSize: 0.01
                            }
                        }

                        Row {
                            spacing: 20
                            Text {
                                width: 100
                                anchors.verticalCenter: parent.verticalCenter;
                                text: "Pn"
                                color: "white"
                            }

                            IntInputBox {
                                id: pnValue
                                width: 150
                                height: 30
                                anchors.verticalCenter: parent.verticalCenter;
                                
                                from: -200000
                                to: 200000
                                value: 100
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter;
                                text: "W"
                                color: "white"
                            }
                        }

                        Row {
                            spacing: 20
                            Text {
                                width: 100
                                anchors.verticalCenter: parent.verticalCenter;
                                text: "Sn"
                                color: "white"
                            }

                            IntInputBox {
                                id: snValue
                                width: 150
                                height: 30
                                anchors.verticalCenter: parent.verticalCenter;
                                
                                from: -200000
                                to: 200000
                                value: 100
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter;
                                text: "VA"
                                color: "white"
                            }
                        }

                        Row {
                            spacing: 20
                            Text {
                                width: 100
                                anchors.verticalCenter: parent.verticalCenter;
                                text: "3 Tau"
                                color: "white"
                            }

                            IntInputBox {
                                id: threeTauValue
                                width: 150
                                height: 30
                                anchors.verticalCenter: parent.verticalCenter;
                                
                                from: 6
                                to: 60
                                value: 10
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter;
                                text: "s"
                                color: "white"
                            }
                        }
                        Row {
                            spacing: 20
                            Text {
                                width: 100
                                anchors.verticalCenter: parent.verticalCenter;
                                text: "Delay time"
                                color: "white"
                            }
                            FloatInputBox {
                                id: delayTimeValue
                                width: 150
                                height: 30
                                anchors.verticalCenter: parent.verticalCenter;
                                
                                from: 0.1
                                to: 2
                                value: 0.6
                                stepSize: 0.01
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter;
                                text: "tau"
                                color: "white"
                            }
                        }

                        Row {
                            spacing: 20
                            Text {
                                width: 100
                                anchors.verticalCenter: parent.verticalCenter;
                                text: "Tolerance Q"
                                color: "white"
                            }

                            FloatInputBox {
                                id: tolQValue
                                width: 150
                                height: 30
                                anchors.verticalCenter: parent.verticalCenter;
                                from: 0.025
                                to: 0.1
                                value: 0.04
                                decimals: 3
                                stepSize: 0.001
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter;
                                text: "p.u."
                                color: "white"
                            }
                        }
                    }

                }
            }
        }

        BaseTextButton {
            anchors.right: parent.right; anchors.bottom: parent.bottom;
            anchors.margins: 30
            text: "Export"
            onClicked: {
                sfd.open()
            }
        }
    }

    FileDialog {
        id: sfd
        // nameFilters: [ "excel files (*.xlsx)" ]
        fileMode: FileDialog.SaveFile
        currentFile: Qt.resolvedUrl("../..") + "/" + root.standard
        onAccepted: {
            root.getSetting()
            reporter.calc(currentFile, ProcessManager.sectionAxis.min, ProcessManager.sectionAxis.max)
            root.close()
        }
        defaultSuffix: "xlsx"
    }

    function open() {
        root.opacity = 1.0
    }

    function close() {
        root.opacity = 0.0
    }

    function getSetting() {
        let settings = reporter.getBaseInfo()

        // Standard settings
        if(vdeChecked.checked) {
            reporter.type = "VDE"
            settings["voltageDepth"] = 0.15
        }
        if(enChecked.checked) {
            reporter.type = "VDE"
            settings["voltageDepth"] = 0.05
        }
        if(bdewChecked.checked) {
            reporter.type = "BDEW"
        }
        if(vde4110Checked.checked) {
            reporter.type = "BDEW"
        }
        if(vde4120Checked.checked) {
            reporter.type = "BDEW"
        }
        reporter.setBaseInfo(settings)

        let pt1Settings = {}
        pt1Settings["Qstart"] = qstartValue.value
        pt1Settings["Qsoll"] = qsollValue.value
        pt1Settings["KRR"] = krrValue.value
        pt1Settings["Pn"] = pnValue.value
        pt1Settings["Sn"] = snValue.value
        pt1Settings["ThreeTau"] = threeTauValue.value
        pt1Settings["DelayTime"] = delayTimeValue.value
        pt1Settings["ToleranceQ"] = tolQValue.value
        reporter.setPt1Curve(pt1Settings)
    }
}