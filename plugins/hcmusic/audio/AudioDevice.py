# -*- coding: utf-8 -*-
"""
AudioDevice plugin is an example plugin, it provides audio functionalities for Inspector

"""
from PySide2.QtCore import QObject, Signal, Property, Slot, QAbstractListModel, Qt, QModelIndex
from PySide2.QtWidgets import QApplication
import pyaudio
import numpy as np
from ..dsp.Node import QtSignal1D, Signal1D, Node
p = pyaudio.PyAudio()


class AudioInputDeviceModel(QAbstractListModel):
    NameRole = Qt.UserRole + 1
    IndexRole = Qt.UserRole + 2
    MaxInputChannels = Qt.UserRole + 3
    DefaultSampleRate = Qt.UserRole + 4

    def __init__(self, parent=None):
        QAbstractListModel.__init__(self, parent)

        self._entries = []

    def data(self, index, role=Qt.DisplayRole):
        if 0 <= index.row() < self.rowCount() and index.isValid():
            item = self._entries[index.row()]
            if role == AudioInputDeviceModel.NameRole:
                return item["name"]
            elif role == AudioInputDeviceModel.IndexRole:
                return item["index"]
            elif role == AudioInputDeviceModel.MaxInputChannels:
                return item["maxInputChannels"]
            elif role == AudioInputDeviceModel.DefaultSampleRate:
                return item["defaultSampleRate"]

    def rowCount(self, parent=QModelIndex()):
        if parent.isValid():
            return 0
        return len(self._entries)

    def roleNames(self):
        roles = dict()
        roles[AudioInputDeviceModel.NameRole] = b"name"
        roles[AudioInputDeviceModel.IndexRole] = b"deviceIndex"
        roles[AudioInputDeviceModel.MaxInputChannels] = b"maxInputChannels"
        roles[AudioInputDeviceModel.DefaultSampleRate] = b"defaultSampleRate"
        return roles

    def update(self, index, name, maxInputChannels, defaultSampleRate):
        # check if it exist in the list
        idx = [i for i, x in enumerate(self._entries) if x['index'] == index]
        idx = idx[0] if len(idx) > 0 else None
        if idx is None:
            self.beginInsertRows(QModelIndex(), self.rowCount(), self.rowCount())
            self._entries.append({
                'index': index,
                'name': name,
                'maxInputChannels': maxInputChannels,
                'defaultSampleRate': defaultSampleRate
            })
            self.endInsertRows()
        else:
            self._entries[idx]['name'] = name
            self._entries[idx]['maxInputChannels'] = maxInputChannels
            self._entries[idx]['defaultSampleRate'] = defaultSampleRate
            self.dataChanged.emit(QModelIndex(idx), QModelIndex(idx))

    def remove(self, indices):
        indices = sorted(indices)
        rm = 0

        for index in indices:
            self.beginRemoveRows(QModelIndex(), index-rm, index-rm)
            self._entries.pop(index-rm)
            self.endRemoveRows()

    @property
    def availableIndices(self):
        return [x.index for x in self._entries]


class AudioDiscoveryModelProvider(QAbstractListModel):
    inputDeviceModelChanged = Signal()
    defaultInputDeviceIndexChanged = Signal()
    defaultOutputDeviceIndexChanged = Signal()

    def __init__(self, parent=None):
        QAbstractListModel.__init__(self, parent)

        self._inputModel = AudioInputDeviceModel(self)
        self.refresh()

    @Property(QObject, final=True, notify=inputDeviceModelChanged)
    def inputDeviceModel(self):
        return self._inputModel

    @Property(int, final=True, notify=defaultInputDeviceIndexChanged)
    def defaultInputDeviceIndex(self):
        return p.get_default_input_device_info()['index']

    @Property(int, final=True, notify=defaultOutputDeviceIndexChanged)
    def defaultOutputDeviceIndex(self):
        return p.get_default_output_device_info()['index']

    @Slot()
    def refresh(self):
        c = p.get_device_count()

        inp = []
        for i in range(c):
            dev = p.get_device_info_by_index(i)
            if dev['maxInputChannels'] > 0:
                self._inputModel.update(
                    dev['index'],
                    dev['name'],
                    dev['maxInputChannels'],
                    dev['defaultSampleRate']
                )
                inp.append(dev['index'])


class AudioInputDevice(Node):
    bufferLengthChanged = Signal()
    rateChanged = Signal()
    activeChanged = Signal()
    deviceIndexChanged = Signal()
    outputChanged = Signal()
    channelsChanged = Signal()

    def __init__(self, parent=None):
        Node.__init__(self, parent)

        self._bufferLength = 1024
        self._output = QtSignal1D()
        self._active = False
        self._rate = 44100
        self._deviceIndex = p.get_default_input_device_info()['index']
        self._stream = None
        self._channels = 1
        QApplication.instance().aboutToQuit.connect(lambda: self.closeDevice())

    @Property(Signal1D, notify=outputChanged)
    def output(self):
        return self._output

    @Property(bool)
    def active(self):
        return self._active

    @active.setter
    def active(self, val):
        if self._active != val:
            self._active = val
            self.activeChanged.emit()

            if self.completed and self._active:
                self.openDevice()
            if self.completed and not self._active:
                self.closeDevice()

    @Property(int)
    def bufferLength(self):
        return self._bufferLength

    @bufferLength.setter
    def bufferLength(self, val):
        if self._bufferLength != val:
            self._bufferLength = val
            self.bufferLengthChanged.emit()

            if self.completed:
                self._output.alloc(self._bufferLength, self._channels)
                self._output.update.emit(0, self._bufferLength)
                if self._active:
                    raise Exception('Changing bufferLength when active is not support yet')

    @Property(int)
    def rate(self):
        return self._rate

    @rate.setter
    def rate(self, val):
        if self._rate != val:
            self._rate = val
            self.rateChanged.emit()

            if self.completed and self._active:
                self.openDevice()

    @Property(int)
    def deviceIndex(self):
        return self._deviceIndex

    @deviceIndex.setter
    def deviceIndex(self, val):
        if self._deviceIndex != val:
            self._deviceIndex = val
            self.deviceIndexChanged.emit()

            if self.completed and self._active:
                self.openDevice()

    @Property(int)
    def channels(self):
        return self._channels

    @channels.setter
    def channels(self, val):
        if self._channels != val:
            self._channels = val
            self.channelsChanged.emit()

            if self.completed:
                self._output.alloc(self._bufferLength, self._channels)
                self._output.update.emit(0, self._bufferLength)
                if self._active:
                    raise Exception('Changing channels when active is not support yet')

    def initialize(self):
        self._output.alloc(self._bufferLength, self._channels)
        self.outputChanged.emit()
        if self._active:
            self.openDevice()

    def openDevice(self):
        self.closeDevice()
        self._stream = p.open(format=pyaudio.paInt16,
            channels=self._channels,
            rate=self._rate,
            input=True,
            output=False,
            frames_per_buffer=self._bufferLength,
            input_device_index=self._deviceIndex,
            stream_callback=self.callback
        )
        self._stream.start_stream()

    def closeDevice(self):
        if self._stream is not None:
            self._stream.close()

    def callback(self, in_data, frame_count, time_info, status):
        buf = np.frombuffer(in_data, dtype=np.int16).astype(np.float32).reshape(-1, self._channels)
        self._output.numpy_array[...] = buf
        self._output.update.emit(0, buf.shape[0])
        return (None, pyaudio.paContinue)


class AudioOutputDevice(Node):
    """Audio Output Device DSP Style

    Limitations:
    TODO Input buffer should be larger
    """
    activeChanged = Signal()
    bufferLengthChanged = Signal()
    channelsChanged = Signal()
    deviceIndexChanged = Signal()
    inputChanged = Signal()
    rateChanged = Signal()

    def __init__(self, parent=None):
        Node.__init__(self, parent)
        self._rate = 44100
        self._deviceIndex = p.get_default_output_device_info()['index']
        self._bufferLength = 1024
        self._input = None
        self._active = False
        self._stream = None
        self._channels = 1
        import queue
        self._q = queue.Queue()

        QApplication.instance().aboutToQuit.connect(lambda: self.closeDevice())

    @Property(int)
    def rate(self):
        return self._rate

    @rate.setter
    def rate(self, val):
        if self._rate != val:
            self._rate = val
            self.rateChanged.emit()

            if self.completed and self._active:
                self.openDevice()

    @Property(int)
    def deviceIndex(self):
        return self._deviceIndex

    @deviceIndex.setter
    def deviceIndex(self, val):
        if self._deviceIndex != val:
            self._deviceIndex = val
            self.deviceIndexChanged.emit()

            if self.completed and self._active:
                self.openDevice()

    @Property(int)
    def bufferLength(self):
        return self._bufferLength

    @bufferLength.setter
    def bufferLength(self, val):
        if self._bufferLength != val:
            self._bufferLength = val
            self.bufferLengthChanged.emit()

            if self.completed and self._active:
                raise Exception('Changing buffer size on the fly is not support yet')

    @Property(int)
    def channels(self):
        return self._channels

    @channels.setter
    def channels(self, val):
        if self._channels != val:
            self._channels = val
            self.channelsChanged.emit()

            if self.complated and self._active:
                raise Exception('Changing buffer size on the fly is not support yet')

    @Property(Signal1D)
    def input(self):
        return self._input

    @input.setter
    def input(self, val):
        if self._input != val:
            if self._input is not None:
                self._input.update.disconnect(self.appendBuffer)

            self._input = val
            self._input.update.connect(self.appendBuffer)
            self.inputChanged.emit()

    @Property(bool)
    def active(self):
        return self._active

    @active.setter
    def active(self, val):
        if self._active != val:
            self._active = val
            self.activeChanged.emit()

            if self.completed and self._active:
                self.openDevice()
            if self.completed and not self._active:
                self.closeDevice()

    def appendBuffer(self, offset, length):
        """append buffer when input buffer changed

        TODO Discussion: should we auto normalize the buffer?
        """
        assert offset == 0 and length == self._input._length, 'Uncompatible node connected'
        assert self._input._channels == self._channels, 'Wrong num of channels expected %d got %d' % (self._channels, self._input._channels)

        data = self._input.numpy_array
        if (np.abs(data) > 16384).any():
            data /= data.max()
            data *= 16384
        data = data.astype(np.int16)
        i = 0
        bl = self._bufferLength
        while i < self._input._length:
            b = data[i: i+bl, :]
            padded = np.pad(b, ((0, bl-b.shape[0]), (0, 0)))
            self._q.put(padded)
            i += bl

    def initialize(self):
        if self._active:
            self.openDevice()

    def openDevice(self):
        self.closeDevice()
        self._stream = p.open(format=pyaudio.paInt16,
                        channels=self._channels,
                        rate=self._rate,
                        output=True,
                        frames_per_buffer=self._bufferLength,
                        input_device_index=self._deviceIndex,
                        stream_callback=self.callback
        )
        self._stream.start_stream()

    def closeDevice(self):
        if self._stream is not None:
            self._stream.close()

    def callback(self, in_data, frame_count, time_info, status):
        data = self._q.get()
        if data is not None:
            if not data.flags['C_CONTIGUOUS']:
                data = np.ascontiguousarray(data)
            return (data, pyaudio.paContinue)


class RemoteAudioDevice(Node):
    activeChanged = Signal()
    portChanged = Signal()
    bufferLengthChanged = Signal()
    accept = Signal(str, arguments=['addr'])
    outputChanged = Signal()
    
    def __init__(self, parent=None):
        Node.__init__(self, parent)
        self._port = 8888
        self._active = False
        self._bufferLength = 1024
        self._stop = False
        self._output = QtSignal1D()
    
    @Property(int, notify=portChanged)
    def port(self):
        return self._port

    @port.setter
    def port(self, val):
        if self._port != val:
            self._port = val
            self.portChanged.emit()

            if self.completed and self._active:
                self.startServer()

    @Property(bool, notify=activeChanged)
    def active(self):
        return self._active

    @active.setter
    def active(self, val):
        if self._active != val:
            self._active = val
            self.activeChanged.emit()

            if self.completed and self._active:
                self.startServer()

    @Property(int, notify=activeChanged)
    def bufferLength(self):
        return self._bufferLength

    @bufferLength.setter
    def bufferLength(self, val):
        if self._bufferLength != val:
            self._bufferLength = val
            self.bufferLengthChanged.emit()

    @Property(Signal1D, notify=outputChanged)
    def output(self):
        return self._output

    def initialize(self):
        self._output.alloc(self._bufferLength, 1)
        if self._active:
            self.startServer()

    def startServer(self):
        import threading
        import socket
        self._s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._s.bind(('0.0.0.0', 6677))
        self._s.listen(1)
        self._t = threading.Thread(target=self._run, args=())
        self._stop = False
        self._t.start()

    def _run(self):
        client, addr = self._s.accept()
        self.accept.emit('%s:%d' % addr)
        
        while not self._stop:
            data = b''
            l = self._bufferLength * 2
            while l > 0:
                d = client.recv(l)
                l -= len(d)
                data += d
            buf = np.frombuffer(data, dtype=np.int16).astype(np.float32).reshape(-1, 1)
            self._output.numpy_array[...] = buf
            self._output.update.emit(0, buf.shape[0])
