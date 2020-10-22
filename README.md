Inspector v0.1
===

## Note
### Tips for Passing Array from Python to QML
1. list will be converted to QVariantList, and it is very **SLOW**. Only use it for small array.
2. Use QByteArray to pass very large array. Take care if you don't want any copies occuring

### About Buffer Sharing between Python and QML
1. QByteArray will be converted to ArrayBuffer
2. Use Float32Array(bytearray) to wrap the array without copy
3. Use Float32Array.buffer prop to retrieve ArrayBuffer used by Float32Array

**Note that some operations will make its new copy of buffer. ex. slice()**

## Writing Your Own Buffer Class
Buffer is stored in row-major
```python
class Buffer(QObject):
    # emit update when your data has changed
    update = Signal()

    @Property(int)
    def channels(self):
        return 1

    @Property(int)
    def length(self):
        return 1

    # readonly property for QML
    @Property(QByteArray)
    def array(self):
        # self._arr.shape must be [?, length]
        # because Float32Array don't have 'stride' parameter
        # https://github.com/tc39/proposal-typedarray-stride
        return QByteArray(self._arr.tobytes())
```

## Directory Definitions

### Plugin Directory
Plugin directory includes highly reusable QML extension modules or libraries. It's recommand to make plugin if your modules has potential to be used in other project. Usually, plugins have no other dependency.

### App Directory
Contains highly reusable module for this project.

### Root Directory
Highly specialized component, usually based on App module.
