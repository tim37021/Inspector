"""PyAudio Example: Play a wave file."""

from PySide2.QtCore import *
from PySide2.QtGui import *
from PySide2.QtWidgets import *

import pyaudio
import numpy as np
import threading

CHUNK = 1024

# instantiate PyAudio (1)
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

    
        self._deviceIndex = -1
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
                if self._stream is not None:
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