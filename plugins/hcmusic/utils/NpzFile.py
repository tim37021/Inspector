import numpy as np
from PySide2.QtCore import Signal, Property, QUrl


"""
from Buffer import SignalOutput, BaseNode

class NpzFile(BaseNode):
    filenameChanged = Signal()
    outputChanged = Signal()

    def __init__(self, parent=None):
        BaseNode.__init__(self, parent)
        self._filename = QUrl()

    @Property(QUrl, notify=filenameChanged)
    def filename(self):
        return self._filename

    @filename.setter
    def filename(self, val):
        if self._filename == val:
            return

        self._filename = val
        self.filenameChanged.emit()

        if self._inited:
            self.initBuffer()

    def initBuffer(self):
        import os.path
        if os.path.isfile(self._filename.toLocalFile()):
            arr = np.load(self._filename.toLocalFile())
            arr = arr['arr_0'].astype(np.float32).transpose()
            self._output = SignalOutput(arr.shape[1], arr.shape[0])
            self.outputChanged.emit()
            self._output.set(arr)
"""