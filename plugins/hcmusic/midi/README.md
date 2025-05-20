# HC Music MIDI Output (`plugins/hcmusic/midi/`)

This package provides classes for MIDI (Musical Instrument Digital Interface) output functionality within the HC Music plugin system. It allows QML applications to discover available MIDI output ports and send various MIDI messages to them.

## `MidiDiscoveryModelProvider` Class

The `MidiDiscoveryModelProvider` class is responsible for discovering and listing available MIDI output devices on the system.

**Purpose:**

To provide a QML-accessible model of available MIDI output ports, enabling users or applications to select a MIDI device for output.

**Key Properties/Models:**

*   **`midiDeviceModel`**: `MidiDeviceModel` (read-only)
    *   An instance of `MidiDeviceModel` that holds the list of discovered MIDI output devices. This model can be directly used by QML views like `ComboBox` or `ListView`.

**`MidiDeviceModel` (Internal Model used by `midiDeviceModel` property):**

The `MidiDeviceModel` is a `QAbstractListModel` that stores information about each discovered MIDI output port.

*   **Roles:**
    *   `name` (`Qt.UserRole + 1`): The human-readable name of the MIDI output port (e.g., "USB MIDI Interface", "Microsoft GS Wavetable Synth").
    *   `deviceIndex` (`Qt.UserRole + 2`): The index of the device in the list. (Note: The actual port name is used for opening devices with `MidiOutputDevice`).

**Methods:**

*   **`refresh()`**: `Slot()`
    *   Scans the system for available MIDI output ports using `mido.get_output_names()` and updates the `midiDeviceModel` with the found ports. This should be called to populate or update the list.
*   **`find(part_name)`**: `Slot(str, result=str)`
    *   Searches through the available MIDI output port names and returns the full name of the first device that contains `part_name` as a substring. This is case-sensitive.
    *   Example: `find("USB")` might return "Focusrite USB MIDI".

## `MidiOutputDevice` Class

The `MidiOutputDevice` class is used to send MIDI messages to a selected MIDI output port.

**Purpose:**

To open a specific MIDI output port and send various types of MIDI messages, such as note on/off, control changes, pitch wheel, etc.

**Key Properties:**

*   **`portName`**: `str`
    *   The name of the MIDI output port to which messages will be sent.
    *   Setting this property attempts to:
        1.  Close any previously opened port.
        2.  Open the new port specified by `val` using `mido.open_output(val)`.
        3.  If successful, the `opened` property becomes `true`.
    *   The port name must be one of the names available from `mido.get_output_names()` (which `MidiDiscoveryModelProvider` lists).
*   **`opened`**: `bool` (read-only)
    *   Indicates whether the MIDI port specified by `portName` is currently open and ready to send messages.

**Methods/Slots for Sending MIDI Messages:**

Once `portName` is set and `opened` is `true`, the following slots can be called to send MIDI messages. All message sending methods check if the `outport` is valid and open before attempting to send.

*   **`note_on(channel, note, velocity)`**: `Slot(int, int, int)`
    *   Sends a Note On message.
    *   `channel`: MIDI channel (0-15).
    *   `note`: MIDI note number (0-127).
    *   `velocity`: Note velocity (0-127).
*   **`note_off(channel, note, velocity)`**: `Slot(int, int, int)`
    *   Sends a Note Off message.
    *   Parameters are the same as `note_on`. (Velocity in Note Off is often used for release velocity).
*   **`polytouch(channel, note, value)`**: `Slot(int, int, int)`
    *   Sends a Polyphonic Aftertouch (Key Pressure) message.
    *   `channel`: MIDI channel (0-15).
    *   `note`: MIDI note number (0-127) for which the pressure applies.
    *   `value`: Pressure value (0-127).
*   **`control_change(channel, control, value)`**: `Slot(int, int, int)`
    *   Sends a Control Change (CC) message.
    *   `channel`: MIDI channel (0-15).
    *   `control`: CC number (0-127) (e.g., 1 for modulation, 7 for volume).
    *   `value`: CC value (0-127).
*   **`program_change(channel, program)`**: `Slot(int, int)`
    *   Sends a Program Change message.
    *   `channel`: MIDI channel (0-15).
    *   `program`: Program/patch number (0-127).
*   **`aftertouch(channel, value)`**: `Slot(int, int)`
    *   Sends a Channel Aftertouch (Channel Pressure) message.
    *   `channel`: MIDI channel (0-15).
    *   `value`: Pressure value (0-127).
*   **`pitchwheel(channel, pitch)`**: `Slot(int, int)`
    *   Sends a Pitch Wheel Change message.
    *   `channel`: MIDI channel (0-15).
    *   `pitch`: Pitch bend value. Typically a 14-bit value, `mido` expects a signed integer from -8192 to +8191. (0 is center).
*   **`sysex(data)`**: `Slot(list)` (Note: The code shows `Slot(int)`, but `mido.Message('sysex', data=data)` expects `data` to be a list or tuple of integers (0-127)).
    *   Sends a System Exclusive (SysEx) message.
    *   `data`: A list of integers representing the SysEx data bytes (excluding the initial 0xF0 and final 0xF7, which `mido` adds).

## QML Examples

### Example 1: Listing MIDI Devices and Sending a Note

This example shows how to use `MidiDiscoveryModelProvider` to populate a ComboBox with available MIDI output devices, and then use `MidiOutputDevice` to send a "Note On" message to the selected device.

```qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import hcmusic.midi 1.0 // Assuming the module is registered

ApplicationWindow {
    visible: true
    width: 400
    height: 300
    title: "MIDI Output Example"

    MidiDiscoveryModelProvider {
        id: midiDiscovery
        Component.onCompleted: {
            midiDiscovery.refresh(); // Populate the model on startup
        }
    }

    MidiOutputDevice {
        id: midiOut
        // portName will be set from the ComboBox
    }

    Column {
        anchors.fill: parent
        padding: 10
        spacing: 10

        Label {
            text: "Select MIDI Output Device:"
        }

        ComboBox {
            id: midiDeviceSelector
            width: parent.width
            model: midiDiscovery.midiDeviceModel
            textRole: "name" // Use the 'name' role from MidiDeviceModel

            onCurrentTextChanged: {
                // When selection changes, set the portName for MidiOutputDevice
                if (currentText) {
                    midiOut.portName = currentText;
                }
            }
        }

        Label {
            text: "MIDI Port Status: " + (midiOut.opened ? "Open (" + midiOut.portName + ")" : "Closed")
        }

        Button {
            text: "Send Note On (C4)"
            enabled: midiOut.opened
            onClicked: {
                // Send a Middle C (note 60) on channel 0 with velocity 100
                midiOut.note_on(0, 60, 100);
                // Optionally, send a Note Off after a delay using a Timer
                noteOffTimer.start();
            }
        }
        
        Button {
            text: "Send Note Off (C4)"
            enabled: midiOut.opened
            onClicked: {
                // Send a Middle C (note 60) on channel 0 with velocity 0
                midiOut.note_off(0, 60, 0);
            }
        }
    }

    Timer {
        id: noteOffTimer
        interval: 500 // ms
        onTriggered: {
            midiOut.note_off(0, 60, 0);
        }
    }
}
```

This README provides an overview of the MIDI output classes in `plugins/hcmusic/midi/`. For more details on MIDI messages and `mido` usage, refer to the `mido` library documentation.
```
