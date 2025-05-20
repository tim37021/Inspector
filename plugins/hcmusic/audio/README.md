hcmusic.audio
===
This module provides audio functionalities to Inspector, primarily through classes defined in `AudioDevice.py`. These classes allow for capturing, processing, and outputting audio streams.

## AudioDevice.py

`AudioDevice.py` contains several QObject-based classes for audio handling:

1.  **`AudioDiscoveryModelProvider`**: Discovers available audio input and output devices and provides models for QML.
    *   `inputDeviceModel`: A model listing available input devices.
    *   `defaultInputDeviceIndex`: The system's default input device index.
    *   `defaultOutputDeviceIndex`: The system's default output device index.
    *   `refresh()`: Slot to refresh the list of devices.

2.  **`AudioInputDevice`**: A `Node` for capturing audio from a selected input device. This is often the primary class used for getting audio into the application.

3.  **`AudioOutputDevice`**: A `Node` for sending audio to a selected output device.

4.  **`RemoteAudioDevice`**: A `Node` for receiving audio data over a network connection.

### AudioInputDevice

The `AudioInputDevice` class is designed to capture audio from a hardware input and provide it as a data stream for further processing.

**Purpose:**

To select an audio input, configure its parameters (sample rate, buffer size, channels), and continuously provide blocks of audio samples as a `Signal1D` output.

**Properties:**

*   **`active`**: `bool`
    *   Controls whether the audio device is currently capturing audio. Setting it to `true` starts capturing, and `false` stops it.
*   **`rate`**: `int`
    *   The desired sample rate in Hz (e.g., 44100, 48000).
    *   The device attempts to open the stream with this rate.
*   **`channels`**: `int`
    *   The number of audio channels to capture (e.g., 1 for mono, 2 for stereo).
*   **`bufferLength`**: `int`
    *   The number of audio frames per buffer. This defines the size of the audio chunk delivered at each update. This is akin to `sampleSize` in terms of defining data block length.
*   **`deviceIndex`**: `int`
    *   The index of the audio input device to use. This can be obtained from `AudioDiscoveryModelProvider.inputDeviceModel` or `AudioDiscoveryModelProvider.defaultInputDeviceIndex`. This corresponds to the `device` property.
*   **`output`**: `Signal1D` (read-only)
    *   The output signal that carries the captured audio data. The data is a NumPy array accessible via `output.numpy_array`.
*   **`volume`**: This class does not have a direct `volume` control property. Volume adjustments would typically be handled by downstream processing nodes.

**Signals:**

*   **`activeChanged()`**: Emitted when the `active` property changes.
*   **`rateChanged()`**: Emitted when the `rate` property changes.
*   **`channelsChanged()`**: Emitted when the `channels` property changes.
*   **`bufferLengthChanged()`**: Emitted when the `bufferLength` property changes.
*   **`deviceIndexChanged()`**: Emitted when the `deviceIndex` property changes.
*   **`outputChanged()`**: Emitted when the `output` signal object itself is changed (e.g., re-allocated).
*   **`output.update(offset, length)`**: This signal, from the `QtSignal1D` object held by the `output` property, is emitted whenever new audio data is available. This effectively serves as the `dataAvailable` signal. `offset` is typically 0 and `length` is `bufferLength`.
*   **`error`**: There isn't a specific `error(string)` signal. Errors during device operation (e.g., unsupported format, device disconnection) will typically raise Python exceptions. These might be caught by the QML environment or Python application logic.

**Slots/Methods:**

*   **`active` property setter (effectively `start()`/`stop()`):**
    *   Setting `active = true` initializes and starts the audio stream.
    *   Setting `active = false` stops and closes the audio stream.
*   **`initialize()`**: Called internally or can be called to ensure the output buffer is allocated. If `active` is true, it will also attempt to open the device.
*   **`openDevice()`**: (Primarily internal) Opens the audio stream. Automatically called when `active` becomes true.
*   **`closeDevice()`**: (Primarily internal) Closes the audio stream. Automatically called when `active` becomes false or on application quit.
*   **`read()`**: There is no direct `read()` method to pull data. Instead, `AudioInputDevice` pushes data by emitting the `output.update` signal when a new buffer is ready.

**QML Example for AudioInputDevice:**

```qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import hcmusic.audio 1.0 // Assuming the module is registered

ApplicationWindow {
    visible: true
    width: 640
    height: 480
    title: "Audio Input Example"

    AudioDiscoveryModelProvider {
        id: audioDiscovery
        Component.onCompleted: {
            console.log("Default input device index:", defaultInputDeviceIndex)
            // You might want to refresh if devices change after startup
            // refresh()
        }
    }

    AudioInputDevice {
        id: audioInput
        active: false // Start inactive
        deviceIndex: audioDiscovery.defaultInputDeviceIndex // Use default device
        rate: 44100
        channels: 1
        bufferLength: 1024

        // Accessing the output signal (Signal1D)
        // output.numpy_array will contain the data when output.update is emitted

        // Example: Connecting to the dataAvailable equivalent
        Component.onCompleted: {
            output.update.connect(processAudioData)
        }

        function processAudioData(offset, length) {
            // console.log("Audio data received:", length, "samples at offset", offset);
            // audioInput.output.numpy_array contains the actual audio data
            // Example: Calculate RMS (requires a custom C++ or Python backend for complex processing)
            // For pure QML, you might send this data to another component or a custom processing element.
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 10

        ComboBox {
            id: deviceSelector
            textRole: "name"
            valueRole: "deviceIndex"
            model: audioDiscovery.inputDeviceModel
            currentIndex: audioDiscovery.inputDeviceModel.count > 0 ? 0 : -1 // Select first if available
            onCurrentIndexChanged: {
                if (currentIndex !== -1) {
                    audioInput.deviceIndex = model.get(currentIndex).deviceIndex;
                }
            }
        }

        Button {
            text: audioInput.active ? "Stop Capture" : "Start Capture"
            onClicked: {
                audioInput.active = !audioInput.active;
            }
        }

        Label {
            text: "Status: " + (audioInput.active ? "Capturing" : "Stopped")
        }
        Label {
            text: "Sample Rate: " + audioInput.rate + " Hz"
        }
        Label {
            text: "Channels: " + audioInput.channels
        }
        Label {
            text: "Buffer Length: " + audioInput.bufferLength + " samples"
        }
    }
}
```

### AudioOutputDevice

The `AudioOutputDevice` class is designed to play back audio data through a hardware output.

**Purpose:**

To select an audio output device, configure its parameters (sample rate, buffer size, channels), and play audio data provided via its `input` (Signal1D) property.

**Properties:**

*   **`active`**: `bool` - Controls if the device is playing audio.
*   **`rate`**: `int` - Desired sample rate.
*   **`channels`**: `int` - Number of audio channels.
*   **`bufferLength`**: `int` - Size of the internal buffer for playback.
*   **`deviceIndex`**: `int` - Index of the audio output device.
*   **`input`**: `Signal1D` - The input signal that provides the audio data to be played.

**Signals:**

*   `activeChanged()`
*   `rateChanged()`
*   `channelsChanged()`
*   `bufferLengthChanged()`
*   `deviceIndexChanged()`
*   `inputChanged()`

**Methods/Slots:**

*   Setting `active = true` starts playback.
*   Setting `active = false` stops playback.
*   `appendBuffer(offset, length)`: Internal slot connected to the `input.update` signal to queue data for playback.

### RemoteAudioDevice

The `RemoteAudioDevice` class allows receiving audio data from a network source.

**Purpose:**

To listen on a network port for incoming audio data and provide it as a `Signal1D` output.

**Properties:**

*   **`active`**: `bool` - Controls if the server is listening.
*   **`port`**: `int` - The network port to listen on.
*   **`bufferLength`**: `int` - Expected buffer length of incoming audio data.
*   **`output`**: `Signal1D` (read-only) - The output signal carrying the received audio data.

**Signals:**

*   `activeChanged()`
*   `portChanged()`
*   `bufferLengthChanged()`
*   `outputChanged()`
*   `accept(string address)`: Emitted when a client connects.

**Methods/Slots:**

*   Setting `active = true` starts the server.
*   Setting `active = false` would ideally stop the server (implementation details for stopping the thread might be needed).
*   `startServer()`: Starts the listening thread.

```
