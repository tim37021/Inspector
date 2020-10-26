pragma Singleton
import QtQuick 2.12

QtObject {
    readonly property int width: 1280
    readonly property int height: 720

    readonly property string server: 'localhost:9002'

    readonly property FontLoader mySystemFont: FontLoader { name: "Arial" }

    readonly property color background: "#26272d"
    readonly property color foreground1: "#2d2e33"
}
