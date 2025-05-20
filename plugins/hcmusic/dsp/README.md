# HC Music DSP Nodes (`plugins/hcmusic/dsp/`)

This directory contains classes for Digital Signal Processing (DSP) within the HC Music plugin system. These classes are designed to be used in a node-based pipeline, allowing for flexible construction of audio and signal processing chains, often controllable via QML.

## Overall Architecture

The DSP system is built around a node-based architecture. Each DSP unit is a "Node" that can be connected to other nodes. Typically, nodes have input and/or output "ports" that carry signal data or derived values.

*   **Signal Data**: Audio or other 1D data is primarily handled by `Signal1D` objects (specifically `QtSignal1D`).
*   **Nodes**: These are QML components (`QQuickItem`) that encapsulate specific DSP functionalities. They can be sources (like `SineSynth`), processors (like `FFT`, `RingBuffer`), or estimators (like `PitchTracker`, `Amplitude`).
*   **Connections**: Nodes are connected by assigning the `output` of one node to the `input` of another. When the source node updates its data, it emits a signal that triggers the connected node to process the new data.

## Core Data Structure

### `Signal1D` (in `Node.py`)

The `Signal1D` class is an abstract base class representing a 1-dimensional signal. It defines an interface for accessing signal properties and data.

**Purpose:** To provide a standardized way to handle streams of 1D data, such as audio samples.

**Key Properties:**

*   `length`: `int` (read-only) - The number of frames or samples in the signal.
*   `channels`: `int` (read-only) - The number of channels in the signal (e.g., 1 for mono, 2 for stereo).
*   `buffer`: `QtCore.QByteArray` (read-only, abstract) - The raw buffer containing the signal data. The concrete implementation (`QtSignal1D`) provides this.

**Key Signals:**

*   `bufferChanged()`: Emitted when the underlying buffer object changes.
*   `channelsChanged()`: Emitted when the number of channels changes.
*   `lengthChanged()`: Emitted when the length of the signal changes.
*   `update(offset, length)`: Emitted when a portion of the signal data has been updated. This is crucial for pipeline processing.

**Key Methods (Abstract):**

*   `slice(offset, length)`: Returns a QByteArray slice of the data.
*   `alloc(length, channels)`: Allocates memory for the signal.
*   `numpy_array`: Property to get a NumPy array view of the data (implemented in `QtSignal1D`).

### `QtSignal1D` (in `Node.py`)

This is the concrete implementation of `Signal1D` used throughout the DSP nodes.

**Purpose:** To provide a tangible 1D signal object that stores data in a `QtCore.QByteArray` and allows efficient interaction with NumPy.

**Implementation Details:**

*   It stores data as a `QtCore.QByteArray`. Data is typically treated as 32-bit floating-point numbers (`np.float32`).
*   `buffer`: Returns the internal `QByteArray`.
*   `alloc(length, channels)`: Allocates a `QByteArray` of `length * channels * 4` bytes.
*   `resize(length)`: Resizes the buffer.
*   `reserve(length)`: Reserves memory, often to the next power of two, for efficiency.
*   `numpy_array`: Provides a NumPy array that directly views the `QByteArray`'s data, allowing for efficient numerical operations. Changes to the NumPy array reflect in the `QByteArray` and vice-versa.

## Base Node Classes

These classes form the foundation for all DSP components.

### `Node` (in `Node.py`)

The most basic building block for DSP components in QML.

**Purpose:** To provide a base `QQuickItem` that integrates with QML's lifecycle.

**Key Features:**

*   Inherits from `QtQuick.QQuickItem`.
*   `componentComplete()`: A QML lifecycle method that is overridden to set a `completed` flag and call `initialize()`.
*   `initialize()`: A virtual method intended to be overridden by derived classes for any setup required after QML component completion (e.g., allocating output buffers).

### `EstimateNode` (in `Node.py`)

A base class for nodes that analyze an input signal and produce some estimated value(s) or trigger events, rather than outputting another signal.

**Purpose:** To process an input signal and derive data or insights from it.

**Key Properties:**

*   `input`: `Signal1D` - The input signal to be processed. When set, its `update` signal is connected to the node's internal `_update` slot.
*   `running`: `bool` - If `true` (default), the node processes incoming data. If `false`, updates are ignored.

**Key Signals:**

*   `inputChanged()`: Emitted when the `input` property changes.
*   `runningChanged()`: Emitted when the `running` property changes.

**Key Methods:**

*   `_update(offset, length)`: Internal slot called when the input signal updates. Calls `update()` if `running` is true.
*   `update(offset, length)`: Abstract method that must be implemented by derived classes to perform the actual estimation logic.

### `ProcessorNode` (in `Node.py`)

A base class for nodes that take an input signal, process it, and produce an output signal.

**Purpose:** To transform an input `Signal1D` into an output `Signal1D`.

**Key Properties:**

*   `input`: `Signal1D` - The input signal.
*   `output`: `Signal1D` (read-only) - The output signal generated by the node. The type of this output signal is determined by the `output_class` argument passed to the constructor (typically `QtSignal1D`).
*   `running`: `bool` - Controls processing.

**Key Signals:**

*   `inputChanged()`
*   `outputChanged()`: Emitted when the `output` property object itself changes (rare).
*   `runningChanged()`

**Key Methods:**

*   `_update(offset, length)`: Similar to `EstimateNode`, triggers `update()`.
*   `update(offset, length)`: Abstract method for derived classes to implement the signal processing logic. Data from `self.input.numpy_array` is processed and written to `self.output.numpy_array`.

## Concrete DSP Nodes

### Buffer Nodes

#### `RingBuffer` (in `Node.py`)

A `ProcessorNode` that implements a fixed-size circular buffer.

**Purpose:** To maintain a rolling window of the most recent signal data.

**Key Properties:**

*   `length`: `int` - The desired length (number of frames) of the ring buffer.
*   `channels`: `int` - The number of channels for the buffer.

**Key Signals:**

*   `lengthChanged()`
*   `channelsChanged()`

**Operation:**

*   `initialize()`: Allocates the `output` buffer to the specified `length` and `channels`.
*   `update(offset, length)`: When new data arrives from `input`, it shifts the existing data in `output` and copies the new data into the end of the buffer. The `output` signal then emits `update(0, self.output.length)`.
    *   Assertion: `length <= self.length` (incoming data block cannot be larger than the ring buffer's total length).

#### `Storage` (in `Node.py`)

A `ProcessorNode` that appends incoming data to its output buffer, up to an optional maximum length.

**Purpose:** To collect or record signal data over time.

**Key Properties:**

*   `channels`: `int` - Number of channels for the storage.
*   `maxLength`: `int` - The maximum number of frames to store. If 0, storage is unbounded (up to memory limits).
*   `full`: `bool` (read-only) - True if `maxLength` is set and has been reached.

**Key Signals:**

*   `channelsChanged()`
*   `maxLengthChanged()`
*   `fullChanged()`

**Operation:**

*   `initialize()`: Allocates the `output` buffer with an initial length of 0.
*   `update(offset, length)`: Appends the new data from `input.numpy_array` to `output.numpy_array`.
    *   If `maxLength` is set, it only appends up to `maxLength`.
    *   Resizes the `output` buffer as needed, potentially reserving more capacity.
    *   Emits `output.update(old_length, new_data_length)`.

### Analysis Nodes

#### `FFT` (in `Node.py`)

A `ProcessorNode` that computes the Fast Fourier Transform of the input signal.

**Purpose:** To analyze the frequency spectrum of a signal.

**Key Properties:**

*   `rate`: `int` - The sample rate of the input signal. Used to calculate the frequency of the peak magnitude.
*   `frequency`: `float` (read-only) - The frequency with the highest magnitude in the computed FFT.

**Key Signals:**

*   `frequencyChanged()`: Emitted when the `frequency` property changes.
*   `rateChanged()`

**Operation:**

*   `initialize()`: Allocates the `output` buffer to match the dimensions of the `input` signal if available.
*   `update(offset, length)`:
    *   Computes `np.abs(np.fft.fft(input_data, axis=0))` and stores it in `output.numpy_array`.
    *   Normalizes the output by its maximum value.
    *   Calculates the dominant frequency based on the `rate` and the bin with the max magnitude.
    *   Emits `output.update(0, length)`.

#### `AutoCorrelation` (in `Node.py`)

A `ProcessorNode` that computes the auto-correlation of the input signal.

**Purpose:** Often used in pitch detection and analyzing periodicity.

**Key Properties:**

*   `rate`: `int` - Sample rate of the input, used to calculate frequency.
*   `minShift`: `int` - Minimum lag (shift) for auto-correlation calculation.
*   `maxShift`: `int` - Maximum lag for auto-correlation calculation.
*   `windowSize`: `int` - The size of the window over which to compute the auto-correlation.
*   `frequency`: `float` (read-only) - Estimated frequency based on the auto-correlation result (typically `rate / lag_of_min_autocorrelation_value`).

**Key Signals:**

*   `frequencyChanged()`
*   `rateChanged()`
*   `minShiftChanged()`
*   `maxShiftChanged()`
*   `windowSizeChanged()`

**Operation:**

*   `initialize()`: Allocates the `output` buffer to `maxShift + 1` length and 1 channel.
*   `update(offset, length)`:
    *   Uses a C++ backend (`cInspector.auto_correlation`) to compute auto-correlation for lags from `minShift` to `maxShift`.
    *   Stores the result in `output.numpy_array`.
    *   Estimates frequency based on the lag with the minimum value in the auto-correlation result within the specified shift range.
    *   Emits `output.update(minShift, maxShift - minShift + 1)`.

#### `PitchTracker` (in `AlgorithmNode.py`)

An `EstimateNode` that estimates the musical pitch of an audio signal.

**Purpose:** To determine the fundamental frequency and musical note of an incoming audio signal.

**Key Properties:**

*   `rate`: `int` - Sample rate of the input audio.
*   `minLag`: `int` - Minimum lag for the internal auto-correlation.
*   `maxLag`: `int` - Maximum lag for the internal auto-correlation.
*   `windowSize`: `int` - Window size for auto-correlation.
*   `threshold`: `int` - Threshold for peak/valley detection in the auto-correlation signal.
*   `channel`: `int` - Selects which channel of the input signal to analyze.
*   `frequency`: `float` (read-only) - Estimated fundamental frequency.
*   `note`: `int` (read-only) - Estimated MIDI note number (rounded).
*   `noteOnset`: `int` (read-only) - The note number at the most recent onset event.

**Key Signals:**

*   `frequencyChanged()`
*   `noteChanged()`
*   `noteOnsetChanged()`
*   `rateChanged()`, `minLagChanged()`, `maxLagChanged()`, `windowSizeChanged()`, `thresholdChanged()`, `channelChanged()`
*   `onset()`: Emitted when a new note onset is detected.
*   `sustain()`: Emitted when the current note is sustained.
*   `offset()`: Emitted when a note offset (silence or end of note) is detected.

**Operation:**

*   `update(offset, length)`:
    *   Performs auto-correlation on the selected channel of the input data.
    *   Uses `best_lag_analyze` (a custom peak/valley picking logic on the ACF) to find the dominant lag.
    *   Calculates frequency from this lag and the `rate`.
    *   Converts frequency to a (potentially non-integer) MIDI note.
    *   Uses a `Smoother` class to process the raw note sequence and detect `onset`, `sustain`, and `offset` events.

#### `Amplitude` (in `AlgorithmNode.py`)

An `EstimateNode` that calculates the amplitude or envelope of an input signal.

**Purpose:** To measure the loudness or overall level of a signal.

**Key Properties:**

*   `offset`: `int` - Interval length for peak detection in the envelope calculation. (The variable name `offset` here is a bit confusing, it means an interval or window for processing).
*   `windowSize`: `int` - (Seems unused in the current `update` logic, but defined).
*   `channel`: `int` - Selects which channel of the input signal to analyze.
*   `amplitude`: `int` (read-only) - The calculated mean amplitude.

**Key Signals:**

*   `amplitudeChanged()`
*   `offsetChanged()`
*   `windowSizeChanged()`
*   `channelChanged()`

**Operation:**

*   `update(offset, length)`:
    *   Calls `getEnvelope` on the selected channel of the input data.
    *   `getEnvelope`: Takes the absolute value of the signal, then finds local maximums over `intervalLength` (property `offset`) segments.
    *   Calculates the mean of these detected peak values and sets it as `_amplitude`.
    *   Emits `amplitudeChanged`. (Note: The signal emitted is `self.amplitudeChanged` but it should be `self.amplitudeChanged.emit()`).

### Synthesis Nodes

#### `SineSynth` (in `Synth.py`)

A `Node` (not `ProcessorNode` or `EstimateNode` as it's a source) that generates a sine wave.

**Purpose:** To produce a basic sinusoidal audio signal.

**Key Properties:**

*   `frequency`: `float` - Frequency of the sine wave in Hz.
*   `rate`: `int` - Sample rate for the generated wave.
*   `amplitude`: `float` - Amplitude of the sine wave (0.0 to 1.0 typically).
*   `length`: `int` - The number of samples to generate per `synth()` call (i.e., buffer length).
*   `phase`: `float` - Current phase of the oscillator, normalized to the range [0, 1). Updated after each `synth()` call to ensure phase continuity.
*   `output`: `QtSignal1D` (read-only) - The output signal where the sine wave is written.

**Key Signals:**

*   `frequencyChanged()`, `rateChanged()`, `amplitudeChanged()`, `lengthChanged()`, `phaseChanged()`
*   `outputChanged()`: When the output `QtSignal1D` object itself is replaced.

**Key Slots/Methods:**

*   `initialize()`: Allocates the `output` buffer.
*   `synth()`: Generates `length` samples of a sine wave based on the current properties and updates `output.numpy_array`. It then emits `output.update(0, self.length)` and adjusts `phase` for continuity.

## QML Usage Examples

### Example 1: SineSynth -> RingBuffer -> FFT

This example shows how to generate a sine wave, feed it into a ring buffer, and then analyze the buffer's content with an FFT node.

```qml
import QtQuick 2.15
import hcmusic.dsp 1.0 // Assuming dsp module is registered

Item {
    SineSynth {
        id: sine
        frequency: 440 // A4 note
        rate: 44100
        amplitude: 0.8
        length: 1024 // Buffer size for synth and FFT
        Component.onCompleted: {
            initialize(); // Initialize output buffer
            synth(); // Generate initial data
        }
    }

    RingBuffer {
        id: ringBuffer
        input: sine.output // Connect SineSynth output to RingBuffer input
        length: sine.length // Match buffer lengths
        channels: 1
        Component.onCompleted: initialize()
    }

    FFT {
        id: fft
        input: ringBuffer.output // Connect RingBuffer output to FFT input
        rate: sine.rate
        Component.onCompleted: initialize()

        // When FFT output is updated, log the dominant frequency
        // output.update is a Signal1D signal
        Connections {
            target: fft.output
            function onUpdate(offset, length) {
                // console.log("FFT updated. Dominant frequency:", fft.frequency + " Hz");
            }
        }
        // Or react to frequency property change
        onFrequencyChanged: {
             // console.log("Dominant frequency changed:", frequency + " Hz");
        }
    }

    // To make it run continuously, you might use a Timer
    Timer {
        interval: Math.floor(sine.length / sine.rate * 1000) - 5 // ms, approx buffer duration
        running: true
        repeat: true
        onTriggered: {
            sine.synth(); // Generate new data, which will propagate
                          // sine.output.update -> ringBuffer.update -> fft.update
        }
    }
}
```

### Example 2: AudioInput -> PitchTracker

This example conceptually shows how an audio input (like `AudioInputDevice` from `hcmusic.audio`) could be connected to a `PitchTracker`.

```qml
import QtQuick 2.15
import hcmusic.dsp 1.0
import hcmusic.audio 1.0 // Assuming audio module is registered

Item {
    // Assume AudioInputDevice is set up elsewhere or like this:
    AudioInputDevice {
        id: audioInput
        active: true
        rate: 44100
        channels: 1
        bufferLength: 1024 // PitchTracker works on chunks of data
        // ... deviceIndex setup ...
        Component.onCompleted: initialize()
    }

    PitchTracker {
        id: pitchTracker
        input: audioInput.output // Connect audio input to PitchTracker
        rate: audioInput.rate
        minLag: 32
        maxLag: 500
        windowSize: 256
        threshold: 150000 // Adjust based on input signal level
        channel: 0

        onFrequencyChanged: {
            // console.log("Estimated Frequency:", frequency.toFixed(2) + " Hz");
        }
        onNoteChanged: {
            // console.log("Estimated Note (MIDI):", note);
        }
        onOnset: {
            // console.log("Note Onset! Note:", note, "(", noteOnset, ")");
        }
    }
}
```

This README provides a comprehensive overview of the DSP classes in `plugins/hcmusic/dsp/`. Refer to the individual source files (`Node.py`, `AlgorithmNode.py`, `Synth.py`) for complete implementation details.
