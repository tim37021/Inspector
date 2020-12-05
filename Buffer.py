import numpy as np
from math import log2, ceil
from PySide2.QtCore import QObject, Signal, Property, Slot, QByteArray, QUrl
from PySide2.QtQuick import QQuickItem


class SignalOutput(QObject):
    """Output of a Node

    The name of this class may change

    it stores raw byte in [channel, length], row major
    """
    update = Signal()
    lengthChanged = Signal()
    channelsChanged = Signal()

    def __init__(self, length, channels, parent=None):
        QObject.__init__(self, parent)
        self._length = length
        self._channels = channels
        self._buf = QByteArray(length * channels * 4, 0)
        self._capacity = length

    def set(self, arr):
        """Inplace update to the output object"""
        assert arr.shape == self.numpy_array.shape, 'Different dimension'
        self.numpy_array[...] = arr
        self.update.emit()

    def shift(self, arr):
        """Push arr and drop the oldest"""
        assert arr.shape[0] == self.numpy_array.shape[0], 'Different number of channels'
        self.numpy_array[:, :-arr.shape[1]] = self.numpy_array[:, arr.shape[1]:]
        self.numpy_array[:, -arr.shape[1]:] = arr
        self.update.emit()

    def append(self, arr):
        """append to buffer, enlarge capacity if necessary"""
        capacity = self._length + arr.shape[1]
        capacity = 2**ceil(log2(capacity))
        self._buf.reserve(capacity * self._channels * 4)
        self._buf.resize((self._length + arr.shape[1]) * self._channels * 4)
        self._length += arr.shape[1]
        self.numpy_array[:, -arr.shape[1]:] = arr
        self.lengthChanged.emit()
        self.update.emit()

    @Property(int, final=True, notify=lengthChanged)
    def length(self):
        return self._length

    @Property(int, final=True, notify=channelsChanged)
    def channels(self):
        return self._channels

    @Property(QByteArray, final=True, notify=update)
    def buffer(self):
        """Return ArrayBuffer in QML that shares memory"""
        return self._buf

    @property
    def numpy_array(self):
        """Get the R/W numpy array view to the output object"""
        return np.frombuffer(memoryview(self._buf), dtype=np.float32).reshape(
            self._channels, self._length
        )


class BufferedSource(QObject):
    update = Signal()
    rowsChanged = Signal()
    colsChanged = Signal()

    def __init__(self, length, channels, shared=False, parent=None):
        QObject.__init__(self, parent)
        self._shared = shared

        self.init(length, channels)

    @Property(int, notify=colsChanged)
    def channels(self):
        return self._arr.shape[0]

    @Property(int, notify=rowsChanged)
    def length(self):
        return self._arr.shape[1]

    @Property(QByteArray, notify=update)
    def array(self):
        if self._shared:
            return self._buf
        else:
            return QByteArray(self._arr.tobytes())

    @property
    def shared(self):
        return self._shared

    def copy_from(self, arr):
        self.init(arr.shape[1], arr.shape[0])
        self._arr[:] = arr

        self.rowsChanged.emit()
        self.colsChanged.emit()
        self.update.emit()

    def init(self, length, channels):
        if self._shared:
            self._buf = QByteArray(length*channels*4, 0)
            self._arr = np.frombuffer(memoryview(self._buf), dtype=np.float32).reshape(channels, length)
        else:
            self._arr = np.zeros((channels, length), dtype=np.float32)

    def consume(self, buf):
        # channels must match
        assert buf.shape[0] == self._arr.shape[0]
        if buf.dtype != np.float32:
            buf = buf.astype(np.float32)

        l = buf.shape[1]
        self._arr[..., :-l] = self._arr[..., l:]
        self._arr[..., -l:] = buf

        self.update.emit()

    @Slot(QUrl)
    def saveToFile(self, url):
        fn = url.toLocalFile()
        arr = self._arr.copy().transpose()
        np.savez_compressed(fn, arr)


class ProcessorNode(QQuickItem):
    inputChanged = Signal()

    outputChanged = Signal()

    def __init__(self, parent):
        QQuickItem.__init__(self, parent)

        self._input = None
        self._output = None
        self._inited = False

    @Property(SignalOutput, notify=inputChanged)
    def input(self):
        return self._input

    @input.setter
    def input(self, val):
        if self._input != val:
            if self._input is not None:
                self._input.update.disconnect(self.update)

            self._input = val
            self._input.update.connect(self.update)
            self.inputChanged.emit()
            if self._inited:
                self.update()

    @Property(SignalOutput, final=True, notify=outputChanged)
    def output(self):
        return self._output

    def alloc(self, outputLength, outputChannels):
        self._output = SignalOutput(outputLength, outputChannels)
        self.outputChanged.emit()

    def update(self):
        raise Exception('Unimplemented update method for Node')

    def initBuffer(self):
        raise Exception('Unimplemented initBuffer method for Node')

    def componentComplete(self):
        self._inited = True
        self.initBuffer()


class StorageNode(ProcessorNode):
    bufferLengthChanged = Signal()
    channelsChanged = Signal()

    def __init__(self, parent=None):
        ProcessorNode.__init__(self, parent)
        self._bufferLength = 0
        self._channels = 0

    @Property(int, notify=bufferLengthChanged)
    def bufferLength(self):
        return self._bufferLength

    @bufferLength.setter
    def bufferLength(self, val):
        if self._bufferLength != val:
            self._bufferLength = val
            self.bufferLengthChanged.emit()

            if self._inited:
                self.initBuffer()

    @Property(int, notify=channelsChanged)
    def channels(self):
        return self._channels

    @channels.setter
    def channels(self, val):
        if self._channels != val:
            self._channels = val
            self.channelsChanged.emit()

            if self._inited:
                self.initBuffer()

    def initBuffer(self):
        self.alloc(self._bufferLength, self._channels)

    @Slot(str)
    def saveToNpz(self, filename):
        np.savez(filename, self._output.numpy_array.transpose())


class RingBuffer(StorageNode):
    def update(self):
        self._output.shift(self._input.numpy_array)


class StorageBuffer(StorageNode):
    def update(self):
        self._output.append(self._input.numpy_array)
