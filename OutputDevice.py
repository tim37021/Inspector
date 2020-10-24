from PySide2.QtCore import *
from PySide2.QtGui import *
from PySide2.QtWidgets import *

import pyaudio
import numpy as np
import threading
import queue

CHUNK = 1024

# instantiate PyAudio (1)
p = pyaudio.PyAudio()

class OutputDevice(QObject):
    rateChanged = Signal()
    deviceIndexChanged = Signal()
    
    def __init__(self, parent=None):
        QObject.__init__(self, parent)
        self._rate = 44100
        self._deviceIndex = -1
        self._stream = None
        self._q = queue.Queue()

        QApplication.instance().aboutToQuit.connect(lambda: self.stop())

    def start(self, data):
        self._stream.write(data)
        print('yoyo')


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
        
        data = np.frombuffer(data, dtype=np.float32).astype(np.int16)
        i = 0
        while i < len(data):
            self._q.put(data[i:i+1024])
            i += 1024

    def callback(self, in_data, frame_count, time_info, status):
        if not self._q.empty():
            data = self._q.get_nowait()
            if data is not None:
                return (data, pyaudio.paContinue)
        else:
            return (np.zeros(1024, dtype=np.int16), pyaudio.paContinue)