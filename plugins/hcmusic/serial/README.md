# hcmusic.serial Module

## Introduction
This module provides serial communication functionalities for QML applications, including device discovery and a proposed interface for serial port operations.

## `VCPDiscoveryModel`

This component continuously scans for connected Virtual COM Ports (VCP) that match a specified filter, making them available as a QML model. It operates using a `QTimer` and does not run in a separate thread.

**Properties:**

*   **`idFilter`**: `regexp`
    *   A QML RegExp literal (or a `Qt.RegExp` object) used to filter devices based on their USB Vendor ID (VID) and Product ID (PID).
    *   The filter pattern should match the format "VID:PID", where VID and PID are 4-digit hexadecimal numbers.
    *   Example: `/0403:\\d+/` would match devices with Vendor ID `0403` (commonly FTDI) and any Product ID.
    *   Default: `/\d\d\d\d:\d\d\d\d/` (matches any valid VID:PID format).
*   **`running`**: `bool`
    *   Set to `true` to start scanning for devices (typically every second).
    *   Set to `false` to stop scanning.

**Example Usage:**

Turn on `running` and set an optional `idFilter`. The model will automatically update.

```qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import hcmusic.serial 1.0 // Assuming module registration

Column {
    VCPDiscoveryModel {
        id: vcpScanner
        running: true
        // Example: Filter for devices with VID 0403 (FTDI) and any PID
        idFilter: /0403:\d+/ 
        // Example: Filter for a specific device (e.g., VID:PID 1A86:7523)
        // idFilter: /1a86:7523/
    }

    ComboBox {
        width: 200
        model: vcpScanner
        textRole: "device" // Display the port name
        onCurrentTextChanged: {
            if (currentIndex !== -1) {
                var currentDevice = vcpScanner.get(currentIndex); // Requires QAbstractListModel get method
                console.log("Selected device:", currentDevice.device, 
                            "VID:", currentDevice.usbVendorId.toString(16), // Display VID in hex
                            "PID:", currentDevice.usbProductId.toString(16)); // Display PID in hex
            }
        }
    }
}
```
*(Note: Accessing model data like `vcpScanner.get(currentIndex)` as shown above requires the model to expose such a method, or for direct property access if using `DelegateModel` or similar. The example focuses on `textRole` which is standard.)*

**Available Model Roles:**

*   **`device`**: `string` - The port name that can be used to open the serial port (e.g., "COM3", "/dev/ttyUSB0").
*   **`usbVendorId`**: `int` - The USB Vendor ID of the device (e.g., `0x0403`).
*   **`usbProductId`**: `int` - The USB Product ID of the device (e.g., `0x7523`).

*(The `Serial.py` code also includes a "TODO Export more info to QML". Additional roles like description or manufacturer could be added in the future.)*

## `SerialPort` (Draft / Proposed API)

**Note: The `SerialPort` component described below is a DRAFT and is NOT YET IMPLEMENTED in `Serial.py`. This section outlines a proposed API for future development.**

This component would provide an interface for direct serial port communication.

**Proposed Properties:**

*   **`port`**: `string` - The name of the serial port to connect to (e.g., "COM3", obtained from `VCPDiscoveryModel`).
*   **`baudRate`**: `int` - The serial baud rate (e.g., 9600, 115200). Default: 9600.
*   **`byteSize`**: `int` - Number of data bits. Default: 8.
*   **`parity`**: `enum` - Parity setting (e.g., None, Even, Odd). Default: None. (In Python's `pyserial`, this is typically a string like 'N', 'E', 'O').
*   **`stopbits`**: `int` or `float` - Number of stop bits (e.g., 1, 1.5, 2). Default: 1.
*   **`pattern`**: `string` - A shorthand string to set `byteSize`, `parity`, and `stopbits`.
    *   Example: "8N1" (8 data bits, No parity, 1 stop bit). This is a common way to specify serial parameters. (Still marked "To be discus[sed]" in the original draft).
*   **`rtscts`**: `bool` - Enable RTS/CTS hardware flow control. Default: `false`.
*   **`dtsdtr`**: `bool` - Enable DSR/DTR hardware flow control. Default: `false`.
*   **`opened`**: `bool` (read-only) - Indicates if the port is successfully opened.

**Proposed Signals:**

*   **`error(string message, int code)`**: Emitted when an error occurs (e.g., port not found, permission denied, configuration error).
*   **`data(ArrayBuffer message)`**: Emitted when new data is received from the serial port. The data is provided as an `ArrayBuffer`.

**Proposed Slots (Methods):**

*   **`send(ArrayBuffer message)`**: Sends binary data from an `ArrayBuffer` to the serial port.
*   **`sendString(string message, string encoding = "utf-8")`**: Sends string data, encoded appropriately.
*   **`recv(int length)`**: (Potentially problematic due to blocking) Attempts to receive a specific number of bytes. *Note: Synchronous `recv` methods can block the QML thread; an asynchronous, signal-based approach for receiving data (like the `data` signal) is generally preferred.*
*   **`open()`**: Explicitly opens the port if `port` and other parameters are set.
*   **`close()`**: Closes the port.

**Draft Example Usage:**

```qml
import QtQuick 2.12
import hcmusic.serial 1.0 // Assuming module registration

SerialPort {
    id: mySerialPort
    port: "COM3" // Set this from VCPDiscoveryModel or user input
    baudRate: 115200
    // pattern: "8N1" // Alternatively, use pattern

    onError: function(message, code) {
        console.error("Serial Error:", message, "Code:", code);
    }

    onData: function(arrayBufferData) {
        var dataView = new Uint8Array(arrayBufferData);
        console.log("Data received (Uint8Array):", dataView);
        // Or process as string if applicable:
        // var textDecoder = new TextDecoder('utf-8');
        // console.log("Data received (string):", textDecoder.decode(arrayBufferData));
    }

    Component.onCompleted: {
        // Example: Sending data after the port is configured (and ideally checked if open)
        // This requires the port to be opened, either automatically on setting 'port'
        // or by an explicit open() call.
        // For a robust application, check mySerialPort.opened status.
        
        // var dataToSend = new Uint8Array([0x01, 0x02, 0x03, 0x04]);
        // mySerialPort.send(dataToSend.buffer); 
        
        // mySerialPort.sendString("Hello Serial!");
    }
}
```
This draft API provides a starting point for a QML-friendly serial port component. The actual implementation would need to handle threading for non-blocking operations carefully.
