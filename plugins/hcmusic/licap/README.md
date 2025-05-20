# HC Music LiCAP Interface (`plugins/hcmusic/licap/`)

This package provides an interface for LiCAP (Light Sensing Capacitive Array Peripheral) hardware devices, allowing them to be used as data sources within the HC Music plugin system, particularly in QML applications and with `hcmusic.dsp` nodes.

## `QLiCAPv1` Class (in `Adapter.py`)

The `QLiCAPv1` class is the primary interface for using LiCAP v1 hardware in QML. It acts as an adapter, fetching data from the LiCAP device and exposing it as a `Signal1D` compatible with the HC Music DSP node framework.

**Purpose:**

To connect to a LiCAP v1 device via a serial port, configure data acquisition parameters (like buffer length and selected channels), and provide the incoming sensor data as a continuous stream for further processing (e.g., by DSP nodes).

**Underlying Mechanism:**

`QLiCAPv1` uses an internal instance of `LiCAPv1` (from `LiCAPDevice.py`). The `LiCAPv1` object handles the low-level communication with the hardware. It runs in a separate thread, continuously reading data from the specified serial port, converting it, and then passing it to `QLiCAPv1` via a callback. `QLiCAPv1` accumulates this data into buffers of a specified `bufferLength` and then emits a signal when a full buffer is ready.

**Key Properties:**

*   **`active`**: `bool`
    *   Controls whether the LiCAP device is currently capturing data.
    *   Setting to `true` attempts to open the device on the specified `port` and start data acquisition.
    *   Setting to `false` stops data acquisition and closes the device.
*   **`port`**: `str` (originally `portName` in the task description, but the code uses `port`)
    *   The name of the serial port where the LiCAP device is connected (e.g., "/dev/ttyUSB0", "COM3").
    *   This must be set before activating the device.
*   **`bufferLength`**: `int`
    *   The number of samples (frames) to collect in each output buffer. Default is 256.
    *   Note: Changing `bufferLength` while `active` is true is not supported and will raise an exception. It should be set before activation or when the device is inactive.
*   **`channels`**: `list`
    *   A list of integer indices specifying which channels from the LiCAP device should be included in the `output` signal. LiCAP v1 provides 6 channels (0-5). Default is `[0, 1, 2, 3, 4, 5]`.
    *   The number of channels in the `output` signal will be `len(self.channels)`.
    *   Note: Changing `channels` while `active` is true is not supported and will raise an exception.
*   **`output`**: `Signal1D` (read-only)
    *   The output signal that carries the captured LiCAP data. The data is a NumPy array accessible via `output.numpy_array`. Each row is a frame, and each column corresponds to a selected channel.

**Signals:**

*   **`activeChanged()`**: Emitted when the `active` property changes.
*   **`portChanged()`**: Emitted when the `port` property changes.
*   **`bufferLengthChanged()`**: Emitted when the `bufferLength` property changes.
*   **`channelsChanged()`**: Emitted when the `channels` list changes.
*   **`error(string message)`**: Emitted when an error occurs, e.g., if the device cannot be opened on the specified `port`.
*   **`output.update(offset, length)`**: This signal, from the `QtSignal1D` object held by the `output` property, is emitted whenever a new buffer of LiCAP data (of `bufferLength` samples) is available. This effectively serves as the "data available" signal. `offset` is typically 0 and `length` is `bufferLength`.

**Methods/Slots (Usage):**

The primary way to control `QLiCAPv1` is by setting its properties:
1.  Set the `port` property to the correct serial port name.
2.  Optionally, set `bufferLength` to the desired number of samples per data block.
3.  Optionally, set `channels` to select specific data channels from the LiCAP device.
4.  Set `active = true` to start data acquisition. The `output.update` signal will then be emitted periodically as new data buffers become available.
5.  Set `active = false` to stop data acquisition.

The `initialize()` method is called automatically when the QML component is complete. If `active` is already true at that point, it will attempt to open the device.

**QML Example:**

This example demonstrates how to instantiate `QLiCAPv1`, configure it, and connect its output to a `RingBuffer` (from `hcmusic.dsp`).

```qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import hcmusic.dsp 1.0      // Assuming dsp module is registered
import hcmusic.licap 1.0    // Assuming licap module is registered

ApplicationWindow {
    visible: true
    width: 640
    height: 480
    title: "LiCAPv1 Example"

    QLiCAPv1 {
        id: licapSource
        port: "/dev/ttyUSB0" // Change to your LiCAP device's serial port
        bufferLength: 512
        channels: [0, 1, 2] // Select first 3 channels
        active: false        // Start inactive

        onError: function(message) {
            console.error("LiCAP Error:", message);
            statusLabel.text = "Error: " + message;
        }

        // The output.update signal indicates new data is ready
        // We don't connect to it directly here, as RingBuffer will do it.
    }

    RingBuffer {
        id: dataBuffer
        input: licapSource.output // Connect LiCAP output to RingBuffer input
        length: licapSource.bufferLength // Match buffer length
        channels: licapSource.channels.length // Match number of selected channels
        Component.onCompleted: initialize() // Important for RingBuffer
    }

    // Example: Displaying the status and a button to start/stop
    Column {
        anchors.centerIn: parent
        spacing: 10

        Label {
            id: statusLabel
            text: licapSource.active ? "Capturing from LiCAP" : "LiCAP Inactive"
        }

        Button {
            text: licapSource.active ? "Stop LiCAP" : "Start LiCAP"
            onClicked: {
                licapSource.active = !licapSource.active;
            }
        }

        Label {
            text: "Port: " + licapSource.port
        }
        Label {
            text: "Buffer Length: " + licapSource.bufferLength
        }
        Label {
            text: "Selected Channels Count: " + licapSource.channels.length
        }
    }

    // To do something with the data in dataBuffer:
    // Connections {
    //     target: dataBuffer.output
    //     function onUpdate(offset, length) {
    //         console.log("RingBuffer updated with LiCAP data. Length:", length);
    //         // dataBuffer.output.numpy_array contains the data
    //     }
    // }
}
```

This README provides an overview of how to use the `QLiCAPv1` class to interface with LiCAP hardware in QML applications. For more details on the underlying serial communication and data processing, refer to `LiCAPDevice.py`.
