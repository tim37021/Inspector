import QtQuick 2.12
import QtQml 2.15
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.1
import App 1.0

import hcmusic.plot 1.0
import hcmusic.dsp 1.0

import ".."

Item {
    id: root
    property var selections: ["CH1", "CH2", "CH3", "CH4", "CH5", "CH6"]
    property var phaseWireType: {
        switch(cb.currentIndex) {
            case 0:
                return "PW3P3W";
            case 1:
                return "PW3P4W";
        }
    }

    ComboBox {
        id: cb
        model: ["三項三線", "三項四線"]
        anchors.top: parent.top; anchors.left: parent.left;
        anchors.margins: 20
        currentIndex: 0
        onCurrentIndexChanged: {
            switch(currentIndex) {
                case AppIcon.PW3P3W:
                    icon.iconType = AppIcon.PW3P3W;
                    break;
                case AppIcon.PW3P4W:
                    icon.iconType = AppIcon.PW3P4W;
                    break;
            }
        }
    }
    
    AppIcon {
        id: icon
        anchors.centerIn: parent
        color: "#FF9110"
        width: Math.max(root.width * 0.2, 80)
        height: width
    }

    Column {
        anchors.horizontalCenter: icon.horizontalCenter
        anchors.bottom: icon.top
        anchors.bottomMargin: 20
        spacing: 10
        Row {
            spacing: 20
            Text {
                text: "電壓"
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }
            ComboBox {
                id: va
                model: root.selections
                anchors.verticalCenter: parent.verticalCenter
                currentIndex: Math.min(0, count)
            }
            Text {
                text: "反轉"
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }
            CheckBox {
                id: rva
                checked: false
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            spacing: 20
            Text {
                text: "電流"
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }
            ComboBox {
                id: ia
                model: root.selections
                anchors.verticalCenter: parent.verticalCenter
                currentIndex: Math.min(3, count)
            }
            Text {
                text: "反轉"
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }
            CheckBox {
                id: ria
                checked: false
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Column {
        anchors.left: icon.right
        anchors.top: icon.bottom
        anchors.leftMargin: 20
        spacing: 10
        Row {
            spacing: 20
            Text {
                text: "Voltage"
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }
            ComboBox {
                id: vb
                model: root.selections
                anchors.verticalCenter: parent.verticalCenter
                currentIndex: Math.min(1, count)
            }
            Text {
                text: "反轉"
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }
            CheckBox {
                id: rvb
                checked: false
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            spacing: 20
            Text {
                text: "Current"
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }
            ComboBox {
                id: ib
                model: root.selections
                anchors.verticalCenter: parent.verticalCenter
                currentIndex: Math.min(4, count)
            }
            Text {
                text: "反轉"
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }
            CheckBox {
                id: rib
                checked: false
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Column {
        anchors.right: icon.left
        anchors.top: icon.bottom
        anchors.rightMargin: 20
        spacing: 10
        Row {
            spacing: 20
            Text {
                text: "Voltage"
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }
            ComboBox {
                id: vc
                model: root.selections
                anchors.verticalCenter: parent.verticalCenter
                currentIndex: Math.min(2, count)
            }
            Text {
                text: "反轉"
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }
            CheckBox {
                id: rvc
                checked: false
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            spacing: 20
            Text {
                text: "Current"
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }
            ComboBox {
                id: ic
                model: root.selections
                anchors.verticalCenter: parent.verticalCenter
                currentIndex: Math.min(5, count)
            }
            Text {
                text: "反轉"
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }
            CheckBox {
                id: ric
                checked: false
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    function getChannels() {
        return [
            va.currentIndex,
            vb.currentIndex,
            vc.currentIndex,
            ia.currentIndex,
            ib.currentIndex,
            ic.currentIndex
        ]
    }

    function getInverses() {
        return [
            rva.checked,
            rvb.checked,
            rvc.checked,
            ria.checked,
            rib.checked,
            ric.checked
        ]
    }
}