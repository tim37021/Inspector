import QtQuick 2.12 as QQ2
import QtQuick.Scene3D 2.15
import Qt3D.Core 2.15
import Qt3D.Render 2.15
import Qt3D.Input 2.15
import Qt3D.Extras 2.15

QQ2.Item {
    id: root

    property color clearColor: "transparent"
    property int viewChannel: 0
    clip: true

    Scene3D {
        anchors.fill: parent
        Entity {
            id: sceneRoot


            components: [
                RenderSettings {
                    activeFrameGraph: ForwardRenderer {
                        clearColor: root.clearColor
                    }
                    renderPolicy: RenderSettings.OnDemand

                },
                // Event Source will be set by the Qt3DQuickWindow
                InputSettings { }
            ]
        }
    }

    QQ2.Component {
        id: template
        SignalEntity { material: SignalStyle  {} }
    }

    function addObject(x, type) {
        switch(type) {
            case 'linestrip':
                type = GeometryRenderer.LineStrip; break;
            default:
                return null
        }
        // create SignalEntity and configure binding
        let obj = template.createObject(sceneRoot, {primitiveType: type})

        // TODO better declarative API, reduce manual binding
        x.update.connect(function (offset, length) {
            let b = x.slice(offset, length)
            obj.update(offset, b);
        })

        obj.material.xAxis = x.xAxis;
        obj.material.yAxis = x.yAxis;
        obj.material.mainColor = Qt.binding(function () { return x.color; })
        obj.material.lineWidth = Qt.binding(function () { return x.lineWidth; })

        obj.enabled = Qt.binding(function() { return x.visible; })

        return obj
    }

    QQ2.Component.onCompleted: {
        // iterate through resources (array-like)
        for(let i=0; i<root.resources.length; i++) {
            let x = root.resources[i];

            if(x instanceof LineSeries) {
                addObject(x, 'linestrip') 
            }

        }
        // we temporary change LineSeries's parent to Item
        // TODO: Removed these when Plot API is stable
        for(let i=0; i<root.children.length; i++) {
            let x = root.children[i];

            if(x instanceof LineSeries) {
                addObject(x, 'linestrip') 
            }

        }

    }

}
