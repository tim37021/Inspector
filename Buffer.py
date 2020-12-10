import numpy as np
from math import log2, ceil
from PySide2.QtCore import QObject, Signal, Property, Slot, QByteArray, QUrl
from PySide2.QtQuick import QQuickItem


class SignalOutput(QObject):
    """Output of a Node

    The name of this class may change

    it stores raw byte in [channel, length], row major
    """
    update = Signal(int, int, arguments=['offset', 'length'])
    lengthChanged = Signal()
    channelsChanged = Signal()

    def __init__(self, length, channels, alloc=True, parent=None):
        QObject.__init__(self, parent)
        self._length = length
        self._channels = channels
        if alloc:
            self._buf = QByteArray(length * channels * 4, 0)
        self._capacity = length

    def set(self, arr):
        """Inplace update to the output object"""
        assert arr.shape == self.numpy_array.shape, 'Different dimension'
        self.numpy_array[...] = arr
        self.update.emit(0, self._length)

    def shift(self, arr):
        """Push arr and drop the oldest"""
        assert arr.shape[0] == self.numpy_array.shape[0], 'Different number of channels %s and %s' % (arr.shape, self.numpy_array.shape)
        self.numpy_array[:, :-arr.shape[1]] = self.numpy_array[:, arr.shape[1]:]
        self.numpy_array[:, -arr.shape[1]:] = arr
        self.update.emit(0, self._length)

    def append(self, arr):
        """append to buffer, enlarge capacity if necessary"""
        capacity = self._length + arr.shape[1]
        capacity = 2**ceil(log2(capacity))
        self._buf.reserve(capacity * self._channels * 4)
        self._buf.resize((self._length + arr.shape[1]) * self._channels * 4)
        oldLength = self._length
        self._length += arr.shape[1]
        self.numpy_array[:, -arr.shape[1]:] = arr
        self.lengthChanged.emit()
        self.update.emit(oldLength, arr.shape[1])

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


class SignalOutputNumpy(SignalOutput):
    """SignalOutput Numpy Implementation

    Direct operate on numpy array, slice can be O(1)
    TODO: Capacity
    """
    def __init__(self, arr, parent=None):
        SignalOutput.__init__(self, arr.shape[1], arr.shape[0], alloc=False, parent=parent)
        self._arr = arr
        self._qarr = QByteArray(self._arr.tobytes())
        self._dirty = False

    def set(self, arr):
        SignalOutput.set(self, arr)
        self._dirty = False

    def shift(self, arr):
        SignalOutput.shift(self, arr)
        self._dirty = False

    def append(self, arr):
        oldLength = self._arr.shape[1]
        self._arr = np.hstack([self._arr, arr])
        self._dirty = True
        self._length += arr.shape[1]
        self.lengthChanged.emit()
        self.update.emit(oldLength, arr.shape[1])

    def setArr(self, arr):
        """setArr

        Just a handy function for workaround with no copy slicing
        """
        self._arr = arr
        if self._length != arr.shape[1]:
            self._length = arr.shape[1]
            self.lengthChanged.emit()
        if self._channels != arr.shape[0]:
            self._channels = arr.shape[0]
            self.channelsChanged.emit()
        self._dirty = True

    @SignalOutput.buffer.getter
    def buffer(self):
        """BufferLineSeries will call this function to get a slice of an array"""
        if self._dirty:
            # Get a copy
            self._qarr = QByteArray(self._arr.tobytes())
            self._dirty = False
        return self._qarr

    def markDirty(self):
        self._dirty = True

    @property
    def numpy_array(self):
        return self._arr


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

        ll = buf.shape[1]
        self._arr[..., :-ll] = self._arr[..., ll:]
        self._arr[..., -ll:] = buf

        self.update.emit()

    @Slot(QUrl)
    def saveToFile(self, url):
        fn = url.toLocalFile()
        arr = self._arr.copy().transpose()
        np.savez_compressed(fn, arr)


class BaseNode(QQuickItem):
    outputChanged = Signal()
    runningChanged = Signal()

    def __init__(self, parent=None):
        QQuickItem.__init__(self, parent)
        self._inited = False
        self._output = None
        self._running = True

    @Property(SignalOutput, final=True, notify=outputChanged)
    def output(self):
        return self._output

    @Property(bool, notify=runningChanged)
    def running(self):
        return self._running

    @running.setter
    def running(self, val):
        if self._running != val:
            self._running = val
            self.runningChanged.emit()

    def alloc(self, outputLength, outputChannels):
        self._output = SignalOutput(outputLength, outputChannels)
        self.outputChanged.emit()

    def initBuffer(self):
        raise Exception('Unimplemented initBuffer method for Node')

    def componentComplete(self):
        self._inited = True
        self.initBuffer()

    @Slot(str)
    def saveToNpz(self, filename):
        np.savez(filename, self._output.numpy_array.transpose())


class ProcessorNode(BaseNode):
    inputChanged = Signal()

    def __init__(self, parent=None):
        BaseNode.__init__(self, parent)
        self._input = None

    @Property(SignalOutput, notify=inputChanged)
    def input(self):
        return self._input

    @input.setter
    def input(self, val):
        if self._input != val:
            if self._input is not None:
                self._input.update.disconnect(self._update)

            self._input = val
            self._input.update.connect(self._update)
            self.inputChanged.emit()

            if self._inited:
                self._update(0, self._input._length)

    def _update(self, offset, length):
        if self._running and self._input is not None:
            self.update(offset, length)

    def update(self, offset, length):
        raise Exception('Unimplemented update method for Node')


class BufferView(ProcessorNode):
    """View to the buffer

    Avoid copying!
    It doesn't matter if [offset, offset+length] lays within input buffer
    """
    channelsChanged = Signal()
    offsetChanged = Signal()
    lengthChanged = Signal()

    def __init__(self, parent=None):
        ProcessorNode.__init__(self, parent)
        self._channels = []
        self._offset = 0
        self._length = 0
        self._output = None

    @Property(list, notify=channelsChanged)
    def channels(self):
        return self._channels

    @channels.setter
    def channels(self, val):
        if self._channels != val:
            self._channels = val
            self.channelsChanged.emit()

            if self._inited:
                self.initBuffer()

    @Property(int, notify=offsetChanged)
    def offset(self):
        return self._offset

    @offset.setter
    def offset(self, val):
        if self._offset != val:
            self._offset = val
            self.offsetChanged.emit()

            if self._inited:
                self.initBuffer()

    @Property(int, notify=lengthChanged)
    def length(self):
        return self._length

    @length.setter
    def length(self, val):
        if self._length != val:
            self._length = val
            self.lengthChanged.emit()

            if self._inited:
                self.initBuffer()

    def update(self, offset, length):
        """
        calculate intersection of [offset, offset+length) and [self._offset, self._offset+self._length)
        for update region

        Some care need to be taken if input array is less than our desired.
        """
        # check intersection
        if offset + length < self._offset or offset > self._offset + self._length:
            return
        if self._output is None:
            self.initBuffer()

        # [offset, offset+length] that needs update
        offset = max(offset, self._offset)
        length = min(length, self._length - (offset - self._offset))
        if offset >= self._output._length:
            if offset == self._output._length:
                # it seems the buffer enlarges, we gonna catch up
                # self._output.append(self._input.numpy_array[self._channels, offset: offset+length])
                # return
                if np.all(np.diff(self._channels) == 1):
                    # this also handles lists of one element
                    channels = slice(self._channels[0], self._channels[-1]+1)
                else:
                    channels = self._channels
                self._output.setArr(self._input.numpy_array[channels, self._offset: offset+length])
            else:
                print([offset, length])
                print([self._output.numpy_array.shape])
                # the buffer doesn't grow correctly
                # this limitation can be release
                raise Exception('The buffer doesnot grow correctly')
        else:
            if np.may_share_memory(self._input.numpy_array, self._output.numpy_array):
                self._output.markDirty()
            else:
                raise Exception('Two array doesnot share memory')
        if self._output.numpy_array.size > 0:
            self._output.update.emit(offset, length)

    def initBuffer(self):
        # arr = self._input.numpy_array[self._channels, self._offset:self._offset+self._length]
        if np.all(np.diff(self._channels) == 1):
            # this also handles lists of one element
            channels = slice(self._channels[0], self._channels[-1]+1)
            ll = channels.stop - channels.start
        else:
            channels = self._channels
            ll = len(self._channels)
        if self._input is not None:
            arr = self._input.numpy_array[channels, self._offset:self._offset+self._length].reshape(ll, -1)
            self._output = SignalOutputNumpy(arr)
            self.outputChanged.emit()


class StorageNode(ProcessorNode):
    bufferLengthChanged = Signal()
    channelsChanged = Signal()

    def __init__(self, parent=None):
        ProcessorNode.__init__(self, parent)
        self._bufferLength = 0
        self._channels = 1

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


class RingBuffer(StorageNode):
    def update(self, offset, length):
        self._output.shift(self._input.numpy_array)


class StorageBuffer(StorageNode):
    maxLengthChanged = Signal()
    fullChanged = Signal()

    def __init__(self, parent=None):
        StorageNode.__init__(self, parent)
        self._maxLength = 0
        self._full = False

    @Property(int, notify=maxLengthChanged)
    def maxLength(self):
        return self._maxLength

    @maxLength.setter
    def maxLength(self, val):
        if self._maxLength != val:
            self._maxLength = val
            self.maxLengthChanged.emit()

            if self._inited:
                self._full = self._output._length < self._maxLength

    @Property(bool, final=True, notify=fullChanged)
    def full(self):
        return self._full

    def update(self, offset, length):
        if self._maxLength > 0:
            length = min(self._maxLength - self._output._length, length)
        if length > 0:
            self._output.append(self._input.numpy_array[..., : length])
        if self._maxLength > 0 and self._output._length >= self._maxLength and not self._full:
            self._full = True
            self.fullChanged.emit()


class Distortion(ProcessorNode):
    gainChanged = Signal()

    def __init__(self, parent=None):
        ProcessorNode.__init__(self, parent)
        self._gain = 1

    @Property(float, notify=gainChanged)
    def gain(self):
        return self._gain

    @gain.setter
    def gain(self, val):
        if self._gain != val:
            self._gain = val
            self.gainChanged.emit()

    def initBuffer(self):
        if self._input is not None:
            self.alloc(self._input._length, self._input._channels)

    def update(self, offset, length):
        if offset == 0:
            self._output.numpy_array[...] = self._input.numpy_array
            arr = self._output.numpy_array
            arr *= self._gain
            arr[arr > 8000] = 8000
            arr[arr < -8000] = -8000
            self._output.update.emit(offset, length)
        else:
            raise Exception('You might connect this to storage node')
