import numpy as np

from PySide2.QtCore import Signal, Property, QUrl, QObject
from Buffer import SignalOutput


class NpzFile(QObject):
    filenameChanged = Signal()
    outputChanged = Signal()

    def __init__(self, parent=None):
        QObject.__init__(self, 1, 1, True, parent)
        self._filename = ''
        self._output = SignalOutput(0, 0)

    @Property(QUrl, notify=filenameChanged)
    def filename(self):
        return self._filename

    @filename.setter
    def filename(self, val):
        if self._filename == val:
            return

        self._filename = val

        arr = np.load(self._filename.toLocalFile())
        arr = arr['arr_0'].astype(np.float32).transpose()

        self._output = SignalOutput(arr.shape[1], arr.shape[0])
        self._output.set(arr)
        self.outputChanged.emit()

    @Property(SignalOutput, final=True, notify=outputChanged)
    def output(self):
        return self._output
