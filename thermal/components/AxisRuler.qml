import QtQuick 2.12
import QtQuick.Controls 2.12

import hcmusic.plot 1.0
import hcmusic.dsp 1.0

Item {
    id: plotUI
    enum Orientation {
        Horizontal,
        Vertical
    }

    enum HDirection {
        LeftToRight,
        RightToLeft
    }

    enum VDirection {
        BottomToTop,
        TopToBottom
    }

    property int orientation: AxisRuler.Horizontal
    property ValueAxis axis: ValueAxis {}

    property real gridSize: 0.2
    property real unit: 10
    property int fix: 0
    property string textColor: "#D3D3D3"
    property int fontPixelSize: 12

    Loader {
        id: gridSize
        anchors.fill: parent
        active: TrackRuler
        sourceComponent: plotUI.orientation === AxisRuler.Horizontal? horizontalComp: verticalComp
    }

    Component {
        id: horizontalComp

        Item {
            Repeater {
                id: rep

                model: Math.max(Math.ceil((axis.max - axis.min).toFixed(3) / stride) + 1, 0)
                property real stride: gridSize
                property real startX: Math.floor(axis.min / stride) * stride
                delegate: Item {
                    visible: x >= 0
                    x: (coordinate - axis.min) / (axis.max - axis.min) * plotUI.width
                    width: rep.stride
                    height: plotUI.height
                    property real coordinate: rep.startX + model.index * rep.stride

                    Text {
                        x: -width / 2
                        text: (parent.coordinate * plotUI.unit).toFixed(plotUI.fix)
                        color: plotUI.textColor
                        font.pixelSize: plotUI.fontPixelSize
                    }
                }
            }
        }
    }

    Component {
        id: verticalComp
        Item {
            Repeater {
                id: repV

                model: Math.ceil((axis.max - axis.min).toFixed(3) / stride) + 1
                property real stride: gridSize
                property real startX: Math.floor(axis.min / stride) * stride

                delegate: Item {
                    y: plotUI.height - (coordinate - axis.min) / (axis.max - axis.min) * plotUI.height
                    width: plotUI.width
                    height: repV.stride

                    property real coordinate: repV.startX + model.index * repV.stride
                    
                    Text {
                        anchors.right: parent.right
                        text; (parent.coordinate * plotUI.unit).toFixed(plotUI.fix)
                        color: plotUI.textColor
                        font.pixelSize: plotUI.fontPixelSize
                    }
                }
            }
        }
    }
}