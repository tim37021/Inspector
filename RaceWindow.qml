import QtQuick 2.12
import App 1.0
import nrf.beacon 1.0
import QtWebSockets 1.12
import QtGraphicalEffects 1.0

SubWindow {
    id: raceWindow
    property TrackedDeviceModel target

    TextInput {
        id: route
        text: 'checkpoint1'

        property string result

        onAccepted: result = text
        Component.onCompleted: result = text
        
    }

    WebSocket {
        id: ws
        active: true
        url: 'ws://localhost:9002/'+route.result+'/publish'
    }

    function passBy(addr) {
        ws.sendTextMessage(JSON.stringify({runner_id: addr}))
    }

    ListView {
        width: 64 * count + spacing * (count-1)

        Behavior on width {
            NumberAnimation { duration: 100 }
        }

        height: 72
        anchors.centerIn: parent

        spacing: 24
        model: target

        orientation: ListView.Horizontal
        delegate: Image {
            id: test
            source: './pic/runner.svg'
            width: 64
            height: 72
            
            antialiasing: true


            ColorOverlay{
                anchors.fill: test
                source:test
            
                color: { 
                    if(passed)
                        return "red"
                    return model.active? "green": "gray"
                }
                antialiasing: true
            }

            Text {
                anchors.top: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                text: model.addr
                color: "white"
            }
            
            property RSSIFilter filter: RSSIFilter {}
            
            // TODO: Potential performance issue
            property real reading_: model.rssi
            property real reading: model.rssi
            property real active: model.active
            property bool passed: false
            property Algorithm algo: Algorithm {
                onIncomming: {
                    raceWindow.passBy(model.addr)
                    passed = true
                }

                onReset: passed = false
            }
            property real lastUpdate: -1

            onReading_Changed: {
                if(Date.now() - lastUpdate > 50) {
                    reading = filter.f(reading_)
                    algo.feed(reading)
                    lastUpdate = Date.now()
                }
            }

            onActiveChanged: if(!active) algo.init()
        
        


            
        }
    }

}