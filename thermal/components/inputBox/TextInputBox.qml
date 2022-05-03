import QtQuick 2.12
import QtGraphicalEffects 1.12

FocusScope {
    id: focusScope
    width: 250; height: 28

    property alias text: textInput.text
    property alias emptyText: typeSomething.text
    property alias readOnly: textInput.readOnly
    property string color: "white"
    property string readOnlyColor: "gray"
    property string placeHolder: "Type in value..."
    signal clear
    signal accepted
    signal editingFinished
    property alias maximumLength: textInput.maximumLength

    onClear: {
        textInput.text=""
    }

    // BorderImage {
    //     source: "images/lineedit-bg.png"
    //     width: parent.width; height: parent.height
    //     border { left: 4; top: 4; right: 4; bottom: 4 }
    // }

    Rectangle {
        color: "transparent"
        radius: 2
        border.width: 2
        border.color: "#707070"
        anchors.fill: parent
    }

    Text {
        id: typeSomething
        anchors.fill: parent; anchors.leftMargin: 8
        verticalAlignment: Text.AlignVCenter
        text: focusScope.placeHolder
        color: focusScope.readOnly? focusScope.readOnlyColor: focusScope.color
        font.italic: true
        font.pointSize: 12
    }

    MouseArea {
        anchors.fill: parent
        onClicked: { focusScope.focus = true; }
    }

    TextInput {
        id: textInput
        anchors { left: parent.left; leftMargin: 8; right: clear.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        focus: true
        color: focusScope.readOnly? focusScope.readOnlyColor: focusScope.color
        selectByMouse: true
        font.pointSize: 12
        clip: true

        onAccepted: focusScope.accepted()
        onEditingFinished: focusScope.editingFinished()
    }

    Image {
        id: clear
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        source: "../../pic/close.svg"
        width: 10
        height: 10
        opacity: 0
        visible: !focusScope.readOnly

        ColorOverlay{
            id: colorOverlay
            anchors.fill: parent
            source: parent
            color: focusScope.color
        }

        MouseArea {
            // allow area to grow beyond image size
            // easier to hit the area on high DPI devices
            anchors.centerIn: parent
            height:focusScope.height
            width: focusScope.height
            onClicked: {
                //toogle focus to be able to jump out of input method composer
                focusScope.focus = false;
                textInput.text = '';
                focusScope.focus = true;
            }
        }
    }

    states: [
        State {
            name: "hasText"; when: (textInput.text != '' || textInput.inputMethodComposing)
            PropertyChanges { target: typeSomething; opacity: 0 }
            PropertyChanges { target: clear; opacity: 1 }
        }
    ]

    transitions: [
        Transition {
            from: ""; to: "hasText"
            NumberAnimation { exclude: typeSomething; properties: "opacity" }
        },
        Transition {
            from: "hasText"; to: ""
            NumberAnimation { properties: "opacity" }
        }
    ]
}