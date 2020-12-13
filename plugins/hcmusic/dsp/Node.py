import PySide2.QtCore as QtCore
import PySide2.QtQuick as QtQuick
from PySide2.QtCore import Property, Signal, Slot
import numpy as np
from math import ceil, log2


class Signal1D(QtCore.QObject):
    """Signal1D for Property Object"""

    bufferChanged = Signal()
    channelsChanged = Signal()
    lengthChanged = Signal()
    update = Signal(int, int, arguments=['offset', 'length'])

    def __init__(self, parent=None):
        QtCore.QObject.__init__(self, parent)
        self._length = 0
        self._channels = 0

    @Property(int, notify=lengthChanged)
    def length(self):
        return self._length

    @Property(int, notify=channelsChanged)
    def channels(self):
        return self._channels

    @Property(QtCore.QByteArray, notify=bufferChanged)
    def buffer(self):
        raise Exception('buffer need to be implemented')

    @Slot(int, int, result=QtCore.QByteArray)
    def slice(self, offset, length):
        raise Exception('Slice unimplemented')

    def alloc(self, length, channels):
        raise Exception('alloc unimplemented')

    def resize(self):
        raise Exception('resize method unimplemented')

    @property
    def numpy_array(self):
        raise Exception('property numpy unimplemented')


class QtSignal1D(Signal1D):
    def __init__(self, parent=None):
        Signal1D.__init__(self, parent)

    @Signal1D.buffer.getter
    def buffer(self):
        return self._buf

    def slice(self, offset, length):
        return QtCore.QByteArray(self.numpy_array[offset, offset+length, :])

    def alloc(self, length, channels):
        self._buf = QtCore.QByteArray(length * channels * 4, 0)
        if self._length != length:
            self._length = length
            self.lengthChanged.emit()
        if self._channels != channels:
            self._channels = channels
            self.channelsChanged.emit()

    def resize(self, length):
        self._buf.resize(length * self._channels * 4)
        self._length = length
        self.lengthChanged.emit()

    def reserve(self, length):
        next_power_of_two = 2**ceil(log2(length))
        self._buf.reserve(next_power_of_two * self._channels * 4)

    @property
    def capacity(self):
        return self._buf.capacity()

    @property
    def numpy_array(self):
        return np.frombuffer(self._buf, dtype=np.float32).reshape(self._length, self._channels)


class Node(QtQuick.QQuickItem):
    def __init__(self, parent=None):
        QtQuick.QQuickItem.__init__(self, parent)
        self.completed = False

    def componentComplete(self):
        self.completed = True
        self.initialize()

    def initialize(self):
        pass


class ProcessorNode(Node):
    inputChanged = Signal()
    outputChanged = Signal()
    runningChanged = Signal()

    def __init__(self, output_class, parent=None):
        Node.__init__(self, parent)
        self._running = True
        self._input = None
        self._output = output_class()

    @Property(Signal1D, notify=inputChanged)
    def input(self):
        return self._input

    @input.setter
    def input(self, val):
        if self._input != val:
            if self._input is not None:
                self._input.update.disconnect(self._update)
            self._input = val
            self.inputChanged.emit()

            self._input.update.connect(self._update)
            if self.completed:
                self._update()

    @Property(Signal1D, final=True, notify=outputChanged)
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

    def _update(self, offset, length):
        if self._running:
            self.update(offset, length)

    def update(self, offset, length):
        raise Exception('Unimplemented update')


class RingBuffer(ProcessorNode):
    lengthChanged = Signal()
    channelsChanged = Signal()

    def __init__(self, parent=None):
        ProcessorNode.__init__(self, QtSignal1D, parent)
        self._length = 0
        self._channels = 1

    @Property(int, notify=lengthChanged)
    def length(self):
        return self._length

    @length.setter
    def length(self, val):
        if self._length != val:
            self._length = val
            self.lengthChanged.emit()

            if self.completed:
                self.initialize()

    @Property(int, notify=channelsChanged)
    def channels(self):
        return self._channels

    @channels.setter
    def channels(self, val):
        if self._channels != self._channels:
            self._channels = val
            self.channelsChanged.emit()

            if self.completed:
                self.initialize()

    def update(self, offset, length):
        assert length <= self._length, 'Incoming data is larger than buffer'
        arr = self._input.numpy_array[offset: offset+length]
        oarr = self._output.numpy_array
        oarr[:-length, :] = oarr[length:, :]
        oarr[-length:, :] = arr
        self._output.update.emit(0, oarr.shape[0])

    def initialize(self):
        self._output.alloc(self._length, self._channels)
        self._output.update.emit(0, self._length)


class Storage(ProcessorNode):
    channelsChanged = Signal()
    maxLengthChanged = Signal()
    fullChanged = Signal()

    def __init__(self, parent=None):
        ProcessorNode.__init__(self, QtSignal1D, parent)
        self._channels = 1
        self._maxLength = 0
        self._full = False

    @Property(int, notify=channelsChanged)
    def channels(self):
        return self._channels

    @channels.setter
    def channels(self, val):
        if self._channels != val:
            self._channels = val
            self.channelsChanged.emit()

            if self.completed:
                pass

    @Property(bool, final=True, notify=fullChanged)
    def full(self):
        return self._full

    @Property(int, notify=maxLengthChanged)
    def maxLength(self):
        return self._maxLength

    @maxLength.setter
    def maxLength(self, val):
        if self._maxLength != val:
            self._maxLength = val
            self.maxLengthChanged.emit()

            if self.completed:
                self._full = self._output._length < self._maxLength

    def update(self, offset, length):
        if self._maxLength > 0:
            length = min(self._maxLength - self._output._length, length)
        if length > 0:
            arr = self._input.numpy_array[offset: offset+length, :]
            if self._output._length + length > self._output.capacity:
                self._output.reserve(self._output._length+length)
            ol = self._output._length

            self._output.resize(self._output._length+length)
            self._output.numpy_array[-length:, :] = arr
            self._output.update.emit(ol, length)
        if self._maxLength > 0 and self._output._length >= self._maxLength and not self._full:
            self._full = True
            self.fullChanged.emit()

    def initialize(self):
        self._output.alloc(0, self._channels)


class FFT(ProcessorNode):
    frequencyChanged = Signal()
    rateChanged = Signal()

    def __init__(self, parent=None):
        ProcessorNode.__init__(self, QtSignal1D, parent)
        self._frequency = 0
        self._rate = 0

    @Property(float, final=True, notify=frequencyChanged)
    def frequency(self):
        return self._frequency

    @Property(int, notify=rateChanged)
    def rate(self):
        return self._rate

    @rate.setter
    def rate(self, val):
        if self._rate != val:
            self._rate = val
            self.rateChanged.emit()

    def update(self, offset, length):
        if self._output.numpy_array.shape != self._input.numpy_array.shape:
            self.initialize()
        arr = self._input.numpy_array[0: length, :]
        arr = self._output.numpy_array[...] = np.abs(np.fft.fft(arr, axis=0))
        arr /= arr.max()
        freq = arr.argmax() * self._rate / length
        if freq != self._frequency:
            self._frequency = freq
            self.frequencyChanged.emit()
        self._output.update.emit(0, length)

    def initialize(self):
        if self._input is not None:
            self._output.alloc(self._input._length, self._input._channels)


class AutoCorrelation(ProcessorNode):
    frequencyChanged = Signal()
    rateChanged = Signal()

    def __init__(self, parent=None):
        ProcessorNode.__init__(self, QtSignal1D, parent)
        self._frequency = 0
        self._rate = 0

    @Property(float, final=True, notify=frequencyChanged)
    def frequency(self):
        return self._frequency

    @Property(int, notify=rateChanged)
    def rate(self):
        return self._rate

    @rate.setter
    def rate(self, val):
        if self._rate != val:
            self._rate = val
            self.rateChanged.emit()

    def update(self, offset, length):
        from cInspector import auto_correlation
        ac = np.zeros(shape=501, dtype=np.float32)
        ac[32:] = auto_correlation(self._input.numpy_array.reshape(-1), 32, 500, 256)
        self._output.numpy_array[...] = ac.reshape(501, 1) 
        self._output.update.emit(0, 501)
        freq = self._rate / (ac[32:].argmin()+32)
        if freq != self._frequency:
            self._frequency = freq
            self.frequencyChanged.emit()

    def initialize(self):
        self._output.alloc(501, 1)
