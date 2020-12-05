# -*- coding: utf-8 -*-
"""
AudioDevice plugin is an example plugin, it provides audio functionalities for Inspector

"""

from PySide2.QtCore import QObject, Signal, Property, Slot, QByteArray, QAbstractListModel, Qt, QModelIndex
from PySide2.QtWidgets import QApplication
from PySide2.QtQuick import QQuickItem

import pyaudio
import numpy as np
import queue
from Buffer import BufferedSource, SignalOutput

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


class AudioInputDevice2(QQuickItem):
    bufferLengthChanged = Signal()
    rateChanged = Signal()
    activeChanged = Signal()
    deviceIndexChanged = Signal()
    outputChanged = Signal()

    def __init__(self, parent=None):
        QQuickItem.__init__(self, parent)

        self._bufferLength = 1024
        self._output = SignalOutput(1024, 1, self)
        self._active = False
        self._rate = 44100
        self._deviceIndex = p.get_default_input_device_info()['index']
        self._stream = None
        self._inited = False
        self._lastTime = 0
        QApplication.instance().aboutToQuit.connect(lambda: self.closeDevice())

    @Property(SignalOutput, notify=outputChanged)
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

            if self._inited and self._active:
                self.openDevice()
            if self._inited and not self._active:
                self.closeDevice()

    @Property(int)
    def bufferLength(self):
        return self._bufferLength

    @bufferLength.setter
    def bufferLength(self, val):
        if self._bufferLength != val:
            self._bufferLength = val
            self.bufferLengthChanged.emit()
            self._output = SignalOutput(val, 1, self)
            self.outputChanged.emit()

            if self._inited and self._active:
                raise Exception('Changing bufferLength when active is not support yet')

    @Property(int)
    def rate(self):
        return self._rate

    @rate.setter
    def rate(self, val):
        if self._rate != val:
            self._rate = val
            self.rateChanged.emit()

            if self._inited and self._active:
                self.openDevice()

    @Property(int)
    def deviceIndex(self):
        return self._deviceIndex

    @deviceIndex.setter
    def deviceIndex(self, val):
        if self._deviceIndex != val:
            self._deviceIndex = val
            self.deviceIndexChanged.emit()

            if self._inited and self._active:
                self.openDevice()

    def componentComplete(self):
        self._inited = True
        if self._active:
            self.openDevice()

    def openDevice(self):
        self.closeDevice()
        self._stream = p.open(format=pyaudio.paInt16,
            channels=1,
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
        import time
        buf = np.frombuffer(in_data, dtype=np.int16).astype(np.float32).reshape(1, -1)
        self._output.set(buf)
        self._lastTime = time.time()
        return (None, pyaudio.paContinue)


class AudioInputDevice(BufferedSource):
    """AudioInputDevice

    Args:
        parent (QObject): Parent node

    Attributes:
        rate (int): Sample rate
        deviceIndex (int): index of the input device
        recording (bool): toggle for recording on/off

    todos:
        Inherits from BufferedSource
    """
    deviceIndexChanged = Signal()
    recordingChanged = Signal()
    rateChanged = Signal()

    def __init__(self, parent=None):
        BufferedSource.__init__(self, 44100*5, 1, True, parent)
        self._recording = False
        self._t = None
        self._stream = None
        self._deviceIndex = p.get_default_input_device_info()['index']
        self._recording = False

        QApplication.instance().aboutToQuit.connect(lambda: self.stop())

    @Property(int, notify=rateChanged)
    def rate(self):
        return 44100

    def start(self):
        self._stream.start_stream()

    def stop(self):
        self._stream.stop_stream()

    @Property(int)
    def deviceIndex(self):
        return self._deviceIndex

    @deviceIndex.setter
    def deviceIndex(self, val):
        if self._deviceIndex != val:
            self.reopen()
            self.deviceIndexChanged.emit()
        self._deviceIndex = val

    @Property(bool)
    def recording(self):
        return self._recording

    @recording.setter
    def recording(self, val):
        if self._recording != val:
            if val:
                if self._stream is None:
                    self.reopen()
                self.start()

            else:
                if self._stream is not None:
                    self.stop()

            self.recordingChanged.emit()
        self._recording = val

    def reopen(self):
        # open stream (2)
        if self._stream is not None:
            self.stop()
        self._stream = p.open(format=pyaudio.paInt16,
            channels=1,
            rate=44100,
            input=True,
            frames_per_buffer=1024,
            input_device_index=self._deviceIndex,
            stream_callback=self.callback
        )
        self._stream.start_stream()

    def callback(self, in_data, frame_count, time_info, status):
        buf = np.frombuffer(in_data, dtype=np.int16).astype(np.float32).reshape(1, -1)

        self.consume(buf)

        return (np.zeros(1024, dtype=np.int16), pyaudio.paContinue)


class AudioOutputDevice(QObject):
    """AudioOutputDevice
    Args:
        parent (QObject): Parent node

    Attributes:
        rate (int): Sample rate
        deviceIndex (int): index of the output device
        recording (bool): toggle for recording on/off
    """

    rateChanged = Signal()
    deviceIndexChanged = Signal()

    def __init__(self, parent=None):
        QObject.__init__(self, parent)
        self._rate = 44100
        self._deviceIndex = p.get_default_output_device_info()['index']
        self._stream = None
        self._q = queue.Queue()
        QApplication.instance().aboutToQuit.connect(lambda: self.stop())

    def start(self, data):
        self._stream.write(data)

    def stop(self):
        if self._stream is not None:
            self._stream.stop_stream()
            self._stream.close()
            self._stream = None

    @Property(int, notify=rateChanged)
    def rate(self):
        return self._rate

    @rate.setter
    def rate(self, val):
        if self._rate != val:
            self._rate = val
            self.reopen()
            self.rateChanged.emit()

    @Property(int)
    def deviceIndex(self):
        return self._deviceIndex

    @deviceIndex.setter
    def deviceIndex(self, val):
        if self._deviceIndex != val:
            self._deviceIndex = val
            self.reopen()
            self.deviceIndexChanged.emit()

    def reopen(self):
        if self._deviceIndex == -1:
            return
        # open stream (2)
        if self._stream is not None:
            self.stop()
        self._stream = p.open(format=pyaudio.paInt16,
                        channels=1,
                        rate=44100,
                        output=True,
                        frames_per_buffer=1024,
                        input_device_index=self._deviceIndex,
                        stream_callback=self.callback
        )
        self._stream.start_stream()

    @Slot(QByteArray)
    @Slot(QByteArray, int)
    def play(self, data, rate=None):
        if rate:
            AudioOutputDevice.rate.fset(self, rate)

        if self._stream is None:
            self.reopen()

        data = np.frombuffer(data, dtype=np.float32)
        if (np.abs(data) > 16384).any():
            data /= data.max()
            data *= 16384
        data = data.astype(np.int16)
        i = 0
        while i < len(data):
            b = data[i: i+1024]
            self._q.put(np.pad(b, (0, 1024-len(b))))
            i += 1024
        self._stream.start_stream()

    def callback(self, in_data, frame_count, time_info, status):
        if not self._q.empty():
            data = self._q.get_nowait()
            if data is not None:
                return (data, pyaudio.paContinue)
        else:
            return (np.zeros(1024, dtype=np.int16), pyaudio.paContinue)


class AudioOutputDevice2(QQuickItem):
    """Audio Output Device DSP Style

    Limitations:
    TODO Input buffer should be larger
    """
    activeChanged = Signal()
    bufferLengthChanged = Signal()
    deviceIndexChanged = Signal()
    inputChanged = Signal()
    rateChanged = Signal()

    def __init__(self, parent=None):
        QQuickItem.__init__(self, parent)
        self._rate = 44100
        self._deviceIndex = p.get_default_output_device_info()['index']
        self._bufferLength = 1024
        self._input = None
        self._active = False
        self._stream = None
        self._inited = False
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

            if self._inited and self._active:
                self.openDevice()

    @Property(int)
    def deviceIndex(self):
        return self._deviceIndex

    @deviceIndex.setter
    def deviceIndex(self, val):
        if self._deviceIndex != val:
            self._deviceIndex = val
            self.deviceIndexChanged.emit()

            if self._inited and self._active:
                self.openDevice()

    @Property(int)
    def bufferLength(self):
        return self._bufferLength

    @bufferLength.setter
    def bufferLength(self, val):
        if self._bufferLength != val:
            self._bufferLength = val
            self.bufferLengthChanged.emit()

            if self._inited:
                raise Exception('Changing buffer size on the fly is not support yet')

    @Property(SignalOutput)
    def input(self):
        return self._input

    @input.setter
    def input(self, val):
        if self._input != val:
            if self._input is not None:
                self._input.changed.disconnect(self.appendBuffer)

            self._input = val
            self._input.changed.connect(self.appendBuffer)
            self.inputChanged.emit()

    @Property(bool)
    def active(self):
        return self._active

    @active.setter
    def active(self, val):
        if self._active != val:
            self._active = val
            self.activeChanged.emit()

            if self._inited and self._active:
                self.openDevice()
            if self._inited and not self._active:
                self.closeDevice()

    def appendBuffer(self):
        """append buffer when input buffer changed

        TODO Discussion: should we auto normalize the buffer?
        """
        data = self._input.numpy_array
        if (np.abs(data) > 16384).any():
            data /= data.max()
            data *= 16384
        data = data.astype(np.int16)
        i = 0
        bl = self._bufferLength
        while i < self._input._length:
            b = data[..., i: i+bl]
            padded = np.pad(b, ((0, 0), (0, bl-b.shape[1])))
            self._q.put(padded)
            i += bl

    def componentComplete(self):
        self._inited = True
        if self._active:
            self.openDevice()

    def openDevice(self):
        self.closeDevice()
        self._stream = p.open(format=pyaudio.paInt16,
                        channels=1,
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
            return (data, pyaudio.paContinue)
