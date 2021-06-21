import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12

Image {
    id: root
    property string color
    enum IconType {
        PW3P3W,
        PW3P4W,
        Clear
    }

    source: {
        switch (iconType) {
            case AppIcon.PW3P3W:
                return "icons/3P3W.png";
            case AppIcon.PW3P4W:
                return "icons/3P4W.png";
            case AppIcon.Clear:
                return "icons/clear.svg";
        }
    }
    fillMode: Image.Stretch
    mipmap: true
    smooth: true
    layer {
        enabled: true
        effect: ColorOverlay {
            color: root.color
        }
    }
    property int iconType: AppIcon.PW3P3W
}