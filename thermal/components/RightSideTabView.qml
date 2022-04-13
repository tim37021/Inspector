import QtQuick 2.12
import QtQuick.Controls 1.4
import QtQuick.Controls 2.14
import QtQuick.Controls.Styles 1.4
import App 1.0

// import hcmusic.audio 1.0
import hcmusic.plot 1.0
import hcmusic.dsp 1.0
import hcmusic.loader 1.0


TabView {
    id: root
    anchors.fill: parent
    anchors.margins: 20
    signal channelSelectChecked
    Tab { 
        title: "Report" 
        EstimatePreviewBox {
            id: previewBox
            anchors.fill: parent;
            anchors.margins: 10
            topModel: DisplaySetting.cursor
            bottomModel: DisplaySetting.previewData
        }
    }

    Tab { 
        title: "Display" 
        Item {
            anchors.fill: parent
            anchors.margins: 10
            ChannelSelectBox {
                id: previewBox
                anchors.fill: parent;
                anchors.margins: 20
                channelModel: DisplaySetting.channelModel
            }

            BaseTextButton {
                anchors.right: parent.right; anchors.bottom: parent.bottom;
                anchors.margins: 10
                width : 100
                height: 60

                text: "確認"
                onClicked: {
                    root.channelSelectChecked()
                }
            }
        }
        
    }

    style: TabViewStyle {
        frameOverlap: 1
        tab: Rectangle {
            color: styleData.selected ? "gray" :"darkgray"
            border.color:  "darkgray"
            implicitWidth: Math.max(text.width + 4, 80)
            implicitHeight: 20
            radius: 2
            Text {
                id: text
                anchors.centerIn: parent
                text: styleData.title
                color: styleData.selected ? "white" : "black"
            }
        }
        frame: Rectangle { color: "transparent" }
    }
}