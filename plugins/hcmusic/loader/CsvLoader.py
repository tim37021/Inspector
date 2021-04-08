from PySide2.QtCore import QUrl, Signal, Property
from PySide2.QtWidgets import QApplication
from ..dsp.Node import QtSignal1D, Node, Signal1D

import numpy as np

class QCsvLoader(Node):
    filenameChanged = Signal()
    outputChanged = Signal()

    def __init__(self, parent=None):
        Node.__init__(self, parent)
        self._header = []
        self._output = QtSignal1D()
        self._filename = ''

        QApplication.instance().aboutToQuit.connect(lambda: self.close())

    @Property(QUrl, notify=filenameChanged)
    def filename(self):
        return self._filename

    @filename.setter
    def filename(self, val):
        if self._filename == val:
            return
        self._filename = val
        self._extractFile(self._filename.toLocalFile())
        self.filenameChanged.emit()

    @Property(Signal1D, final=True, notify=outputChanged)
    def output(self):
        return self._output

    def close(self):
        pass

    def initialize(self):
        self._output.alloc(0, 6)

    def _extractFile(self, filename):
        self._header = np.genfromtxt(filename, delimiter = ',', skip_header = 2, max_rows = 8, dtype = str) 
        buf =np.genfromtxt(filename, delimiter = ',', skip_header = 10, usecols = (1, 2, 3, 4, 5, 6))
        length, _ = buf.shape
        self._output.resize(length)
        print(length)
        self._output.numpy_array[:, :] = buf[:, :]
        print(self._output.numpy_array)
        if length > 0:
            self._output.update.emit(0, length)
