from PySide2.QtCore import *
from PySide2.QtGui import *
from PySide2.QtWidgets import *

import pyaudio
import numpy as np
import threading
import queue

p = pyaudio.PyAudio()

class InputDevice(QObject):
    update = Signal()
    rowsChanged = Signal()
    colsChanged = Signal()
    deviceIndexChanged = Signal()
    recordingChanged = Signal()
    rateChanged = Signal()
    
    def __init__(self, parent=None):
        QObject.__init__(self, parent)
        self._recording = False
        self._t = None
        self._stream = None
        self._buf = np.zeros((1, 44100*5), dtype=np.float32)
        
        self._arrs = QByteArray(self._buf.tobytes())

        self._deviceIndex = p.get_default_input_device_info()['index']
        self._recording = False

        QApplication.instance().aboutToQuit.connect(lambda: self.stop())

    @Property(int, notify=rateChanged)
    def rate(self):
        return 44100
            
    @Property(int, notify=colsChanged)
    def channels(self):
        return self._buf.shape[0]

    @Property(int, notify=rowsChanged)
    def length(self):
        return self._buf.shape[1]

    def start(self):
        self._stream.start_stream()

    def stop(self):
        self._stream.stop_stream()
        
    @Property(int)
    def deviceIndex(self):
        return self._deviceIndex

    @deviceIndex.setter
    def setDeviceIndex(self, val):
        if self._deviceIndex != val:
            self.reopen()
            self.deviceIndexChanged.emit()
        self._deviceIndex = val


    @Property(bool)
    def recording(self):
        return self._recording

    @recording.setter
    def setRecording(self, val):
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
        l = buf.shape[1]

        self._buf[..., :-l] = self._buf[..., l:]
        self._buf[..., -l:] = buf

        self._arrs = QByteArray(self._buf.tobytes())
        self.update.emit()

        return (np.zeros(1024, dtype=np.int16), pyaudio.paContinue)

    @Property(QByteArray, notify=update)
    def array(self):
        return self._arrs

class OutputDevice(QObject):
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
    def setRate(self, val):
        if self._rate != val:
            self._rate = val
            self.reopen()
            self.rateChanged.emit()

    @Property(int)
    def deviceIndex(self):
        return self._deviceIndex

    @deviceIndex.setter
    def setDeviceIndex(self, val):
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
            self.setRate(rate)

        if self._stream is None:
            self.reopen()
        
        data = np.frombuffer(data, dtype=np.float32)
        if (np.abs(data) > 16384).any():
            data /= data.max()
            data *= 16384
        data = data.astype(np.int16)
        i = 0
        while i < len(data):
            b = data[i:i+1024]
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