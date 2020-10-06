import QtQuick 2.12
import App 1.0
import nrf.beacon 1.0

SubWindow {
    property TrackedDeviceModel target

    ListView {
        width: parent.width * 0.8
        height: parent.height * 0.8
        anchors.centerIn: parent
        model: target
        delegate: Text {
            text: model.addr
            color: { 
                if(passed)
                    return "red"
                return model.active? "green": "gray"
            }
            property RSSIFilter filter: RSSIFilter {}
            
            // TODO: Potential performance issue
            property real reading_: model.rssi
            property real reading: model.rssi
            property real active: model.active
            property bool passed: false
            property Algorithm algo: Algorithm {
                onIncomming: {
                    app.passBy(model.addr)
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