import numpy as np

from PySide2.QtCore import *

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