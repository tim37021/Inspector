# HC Music Utilities (`plugins/hcmusic/utils/`)

This directory contains utility components for the HC Music QML plugin system.

## `TimeoutModel.qml`

A specialized QML `ListModel` where items can be marked as inactive ("grayed out") after a certain duration and then automatically removed after a longer timeout. This is useful for displaying transient information or events that should fade and then disappear.

**Purpose:**

To manage lists of temporary items, visually indicating their age by changing their state and eventually removing them, without manual intervention for each item's lifecycle.

**Key Properties:**

*   **`timeout`**: `real` (default: `4000` ms)
    *   The total duration (in milliseconds) an item will remain in the model before being automatically removed.
*   **`grayout`**: `real` (default: `timeout - 1000` ms, i.e., `3000` ms by default)
    *   The duration (in milliseconds) after which an item in the model will have its `active` role set to `false`. This allows UI delegates to visually distinguish "aging" items (e.g., by changing their color or opacity).
    *   It is expected that `grayout < timeout`.

**Key Function:**

*   **`update(key, modelData, userData)`**:
    *   Adds a new item to the model or refreshes an existing one.
    *   **`key`**: `string` or `variant` - A unique identifier for the item. If an item with this `key` already exists in the model, its timestamp is refreshed, its `active` state is set to `true`, and its data is updated with `modelData`. If the `key` is new, a new item is appended.
    *   **`modelData`**: `object` - A JavaScript object containing the data roles for the item (e.g., `{ name: "Event A", value: 123 }`). The `TimeoutModel` will automatically add or update an `active: true` role to this object when the item is added or refreshed.
    *   **`userData`**: `variant` (optional) - Arbitrary data that can be associated with the item. This data is stored internally by the model but is not directly exposed as a model role. It can be useful for more complex scenarios where extra context is needed when an item is interacted with or processed.

**Lifecycle of Items:**

1.  **Addition/Update**: When `update()` is called:
    *   If the `key` is new, a new item is appended to the model. `active` is set to `true`.
    *   If the `key` exists, the existing item is updated. Its `active` role is set to `true`, its data roles are updated from `modelData`, and its internal timestamp is reset to the current time.
2.  **Grayout**: A `Timer` within `TimeoutModel` periodically checks the age of items.
    *   When the time elapsed since an item's last update (`timestamp`) is greater than or equal to `grayout`, its `active` role is set to `false` (i.e., `root.set(index, {active: false})`).
3.  **Removal**:
    *   When the time elapsed since an item's last update is greater than or equal to `timeout`, the item is automatically removed from the model.

**QML Example:**

```qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import hcmusic.utils 1.0 // Assuming module registration

ApplicationWindow {
    visible: true
    width: 400
    height: 300
    title: "TimeoutModel Example"

    TimeoutModel {
        id: eventModel
        timeout: 5000 // Items removed after 5 seconds
        grayout: 3000 // Items marked inactive after 3 seconds
    }

    Column {
        anchors.fill: parent
        spacing: 10
        padding: 10

        Button {
            text: "Add/Update Event A"
            onClicked: {
                eventModel.update("eventA", { 
                    description: "Critical Alert", 
                    value: Math.random().toFixed(2) 
                }, {
                    details: "Some extra context for Event A" 
                });
            }
        }

        Button {
            text: "Add/Update Event B"
            onClicked: {
                eventModel.update("eventB", { 
                    description: "Warning Message", 
                    value: Math.floor(Math.random() * 100)
                });
            }
        }

        ListView {
            width: parent.width
            height: 200
            model: eventModel
            delegate: Rectangle {
                width: ListView.view.width
                height: 40
                color: model.active ? "lightgreen" : "lightgray" // Change color based on 'active' state
                border.color: "gray"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 5
                    text: model.description + ": " + model.value
                    font.strikeout: !model.active // Example: strikeout if not active
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 5
                    text: model.active ? "Active" : "Inactive"
                    font.italic: !model.active
                }
                
                // To access userData (not directly a model role):
                // You would typically do this if you had a reference to the
                // internal 'priv.metaData[key].userData' via a custom function
                // in TimeoutModel or if the delegate had access to the key.
            }
        }
    }
}
```

## `NpzFile.py`

This Python file (`plugins/hcmusic/utils/NpzFile.py`) contains a commented-out Python class named `NpzFile`.

**Intended Purpose (based on the commented code):**

The class appears to be designed as a node (possibly for a DSP/data processing chain) that would:
1.  Take a `filename` (as a `QUrl`) pointing to a NumPy `.npz` archive file.
2.  Load the `.npz` file using `numpy.load()`.
3.  Extract an array named `'arr_0'` from the archive.
4.  Process this array (convert to `float32`, transpose).
5.  Make this data available as an output signal (presumably via a `SignalOutput` object, which is not defined in this file but likely part of the broader `hcmusic` framework).

**Current Status:**

The `NpzFile` class is **currently not active** as its entire implementation is commented out in the Python file. It represents a potential future utility for loading data from NumPy's compressed archive format.

## C++ Extension (`hcmusic-utils`)

The `qmldir` file for this module includes the line:
```
plugin hcmusic-utils
```
This signifies that a native C++ plugin (e.g., `hcmusic-utils.dll` on Windows, `libhcmusic-utils.so` on Linux) is associated with the `hcmusic.utils` QML module.

While `TimeoutModel.qml` is a pure QML component, this C++ plugin might provide:
*   Performance-critical helper functions or classes for other utilities within this module (though none are explicitly imported or used by `TimeoutModel.qml`).
*   Underlying implementations for other components that might be part of the `hcmusic` ecosystem.
*   Future utilities that require native code for performance or system access.

Currently, there are no QML components in this directory that directly expose functionalities from this C++ plugin to the QML user. Its role is likely supportive or for other parts of the broader plugin system.
```
