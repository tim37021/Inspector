import QtQuick 2.12
import QtQml 2.15
import QtQuick.Controls 2.14
import Qt.labs.platform 1.1
import App 1.0

import hcmusic.plot 1.0
import hcmusic.dsp 1.0

import ".."

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
                            text: "Test Condition"
                            color: "white"
                            font.pixelSize: 16
                        }

                        Row {
                            spacing: 20
                            Text {
                                anchors.verticalCenter: parent.verticalCenter;
                                text: "P"
                                color: "white"
                            }

                            Rectangle {
                                width: 80
                                height: 30
                                anchors.verticalCenter: parent.verticalCenter;
                                color: "white"

                                TextInput {
                                    id: pValue
                                    text: "100"
                                    anchors.verticalCenter: parent.verticalCenter;
                                    anchors.left: parent.left;anchors.right: parent.right;
                                    anchors.margins: 5
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter;
                                text: "%Pn"
                                color: "white"
                            }
                        }

                        Row  {
                            width: parent.width
                            height: 100
                            spacing: 20

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Q Function"
                                width: 120
                                color: "white"
                            }

                            Rectangle {
                                height: parent.height
                                anchors.verticalCenter: parent.verticalCenter
                                width: 1
                                color: "#F0F0F0"
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                
                                ButtonGroup { id: qRadioGroup }
                                Row {
                                    spacing: 20
                                    RadioButton {
                                        id: qChecked
                                        checked: true
                                        ButtonGroup.group: qRadioGroup
                                    }

                                    Text {
                                        text: "Fixed Q: "
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: qChecked.checked? "white": "#8E8E8E"
                                    }

                                    Rectangle {
                                        width: 100
                                        height: 30
                                        color: qChecked.checked? "white": "#8E8E8E"
                                        anchors.verticalCenter: parent.verticalCenter;

                                        TextInput {
                                            id: qInput
                                            text: "0"
                                            anchors.verticalCenter: parent.verticalCenter;
                                            anchors.left: parent.left;anchors.right: parent.right;
                                            anchors.margins: 5
                                            readOnly: !qChecked.checked
                                        }
                                    }

                                    Text {
                                        text: "% Pn"
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: qChecked.checked? "white": "#8E8E8E"
                                    }
                                }

                                Row {
                                    spacing: 20
                                    RadioButton {
                                        id: cosChecked
                                        checked: true
                                        ButtonGroup.group: qRadioGroup
                                    }

                                    Text {
                                        text: "Fixed cosφ: "
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: cosChecked.checked? "white": "#8E8E8E"
                                    }

                                    Rectangle {
                                        width: 100
                                        height: 30
                                        color: cosChecked.checked? "white": "#8E8E8E"
                                        anchors.verticalCenter: parent.verticalCenter;

                                        TextInput {
                                            id: cosInput
                                            text: "0"
                                            anchors.verticalCenter: parent.verticalCenter;
                                            anchors.left: parent.left;anchors.right: parent.right;
                                            anchors.margins: 5
                                            readOnly: !cosChecked.checked
                                        }
                                    }

                                    Text {
                                        text: "% Pn"
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: cosChecked.checked? "white": "#8E8E8E"
                                    }
                                }
                            }
                        }

                        Row  {
                            width: parent.width
                            height: 100
                            spacing: 20

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "K factor"
                                width: 120
                                color: "white"
                            }

                            Rectangle {
                                height: parent.height
                                anchors.verticalCenter: parent.verticalCenter
                                width: 1
                                color: "#F0F0F0"
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                
                                ButtonGroup { id: kRadioGroup }
                                Row {
                                    spacing: 20
                                    RadioButton {
                                        id: k1Checked
                                        checked: true
                                        ButtonGroup.group: kRadioGroup
                                    }

                                    Text {
                                        text: ""
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: k1Checked.checked? "white": "#8E8E8E"
                                    }

                                    Rectangle {
                                        width: 100
                                        height: 30
                                        color: k1Checked.checked? "white": "#8E8E8E"
                                        anchors.verticalCenter: parent.verticalCenter;

                                        TextInput {
                                            id: k1Input
                                            text: "0"
                                            anchors.verticalCenter: parent.verticalCenter;
                                            anchors.left: parent.left;anchors.right: parent.right;
                                            anchors.margins: 5
                                            readOnly: !k1Checked.checked
                                        }
                                    }

                                    Text {
                                        text: ""
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: k1Checked.checked? "white": "#8E8E8E"
                                    }
                                }

                                Row {
                                    spacing: 20
                                    RadioButton {
                                        id: zeroChecked
                                        checked: true
                                        ButtonGroup.group: kRadioGroup
                                    }

                                    Text {
                                        text: "Zero current"
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: "white"
                                    }
                                }
                            }
                        }

                        Row  {
                            width: parent.width
                            height: 100
                            spacing: 20

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Recover Q"
                                width: 120
                                color: "white"
                            }

                            Rectangle {
                                height: parent.height
                                anchors.verticalCenter: parent.verticalCenter
                                width: 1
                                color: "#F0F0F0"
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                
                                ButtonGroup { id: recoverQRadioGroup }
                                Row {
                                    spacing: 20
                                    RadioButton {
                                        id: ptChecked
                                        checked: true
                                        ButtonGroup.group: recoverQRadioGroup
                                    }

                                    Text {
                                        text: "PT1 curve"
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: "white"
                                    }
                                }

                                Row {
                                    spacing: 20
                                    RadioButton {
                                        id: fastChecked
                                        checked: true
                                        ButtonGroup.group: recoverQRadioGroup
                                    }

                                    Text {
                                        text: "Fast"
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: "white"
                                    }
                                }
                            }
                        }
                        
                    }

                    Row {
                        id: timeSelect
                        width: parent.width
                        height: 100
                        spacing: 20

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Fault time (sample)"
                            width: 120
                            color: "white"
                        }

                        Rectangle {
                            height: parent.height
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            color: "#F0F0F0"
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            
                            ButtonGroup { id: radioGroup }
                            Row {
                                RadioButton {
                                    id: autoChecked
                                    checked: true
                                    ButtonGroup.group: radioGroup
                                }

                                Text {
                                    text: "Auto"
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: autoChecked.checked? "white": "#8E8E8E"
                                }
                            }

                            Row {
                                spacing: 20
                                RadioButton {
                                    id: manualChecked
                                    checked: true
                                    ButtonGroup.group: radioGroup
                                }

                                Text {
                                    text: "T1"
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: manualChecked.checked? "white": "#8E8E8E"
                                }

                                Rectangle {
                                    width: 100
                                    height: 30
                                    color: manualChecked.checked? "white": "#8E8E8E"
                                    anchors.verticalCenter: parent.verticalCenter;

                                    TextInput {
                                        id: t1Input
                                        text: "0"
                                        anchors.verticalCenter: parent.verticalCenter;
                                        anchors.left: parent.left;anchors.right: parent.right;
                                        anchors.margins: 5
                                        readOnly: !manualChecked.checked
                                    }
                                }

                                Text {
                                    text: "T2"
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: manualChecked.checked? "white": "#8E8E8E"
                                }

                                Rectangle {
                                    width: 100
                                    height: 30
                                    color: manualChecked.checked? "white": "#8E8E8E"
                                    anchors.verticalCenter: parent.verticalCenter;

                                    TextInput {
                                        id: t2Input
                                        text: "2000"
                                        anchors.verticalCenter: parent.verticalCenter;
                                        anchors.left: parent.left; anchors.right: parent.right;
                                        anchors.margins: 5
                                        readOnly: !manualChecked.checked
                                    }
                                }
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
            reporter.calc(currentFile)
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
    }
}