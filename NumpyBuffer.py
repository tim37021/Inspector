import numpy as np

from PySide2.QtCore import *
from Buffer import BufferedSource

class NumpyBuffer(BufferedSource):
    filenameChanged = Signal()
    rateChanged = Signal()

    def __init__(self, parent=None):
        BufferedSource.__init__(self, 1, 1, True, parent)
        self._filename = ''

    @Property(int, notify=rateChanged)
    def rate(self):
        return 32000

    @Property(QUrl, notify=filenameChanged)
    def filename(self):
        return self._filename

    @filename.setter
    def setFilename(self, val):
        if self._filename == val:
            return

        self._filename = val

        arr = np.load(self._filename.toLocalFile())
        arr = arr['arr_0'].astype(np.float32).transpose()

        self.copy_from(arr)
