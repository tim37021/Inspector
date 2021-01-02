# hcmusic.serial Module
## Introduction
This module provide serial access to QML.

## VCPDiscoveryModel
Properties:
- idFilter regex for vid:pid
- running bool

Turn on running and that's it. It will continiously scan for devices every second.
**(No Thread)**
```qml
VCPDiscoveryModel {
    id: vcpScanner
    running: true
    idFilter: /0403:\d+/
}

ComboBox {
    model: vcpScanner
    textRole: 'device'
}
```

### Available Roles
- device - port name
- usbVendorId
- usbProductId

## SerialPort Draft
Properties:
- port string
- baudRate int (default to 9600)
- byteSize int (default to 8)
- parity bool (default to False)
- stopbits int (default to 1)
- (To be discus) pattern str (default to '8N1')
- rtscts bool
- dtsdtr bool

Signals:
- error
- data(ArrayBuffer message)

Slots:
- send(ArrayBuffer message)
- recv(int length) - Receive specific bytes

### Example Usage
```qml
SerialPort {
    port: 'COM3'
    pattern: '8N1'
    onError: {

    }
    onData: {
        console.log(new Uint8Array(message))
    }
}
```
