import QtQuick 2.12
import nrf.beacon 1.0

QtObject {
    id: deviceMgr
    signal devicePlugged(string port)
    signal deviceUnplugged(string port)

    property alias enumerate: bleEnum.running;

    readonly property BeaconScannerEnumModel enumModel: BeaconScannerEnumModel {
        id: bleEnum
        running: true

        onDataChanged: {
            let port = data(topLeft)
            _scanners[port] = template.createObject(null, {port_: port})
            deviceMgr.devicePlugged(port)
        }
        onRowsAboutToBeRemoved: {
            let port = get(first)
            _scanners[port].destroy()
            delete _scanners[port]
            deviceMgr.deviceUnplugged(port)
        }
    }
    readonly property Component template: Component{
        BeaconScanner {
            id: scanner
            property string port_            

            running: true
            readonly property TrackedDeviceModel model: TrackedDeviceModel {
            }

            function open() { port = port_ }
            function close() { port = '' }

            onReport: model.update(addr, rssi)
        }
    }

    readonly property var _scanners: ({})

    function getScanner(port) {
        if(port in _scanners)
            return _scanners[port]
        else
            return null
    }
}