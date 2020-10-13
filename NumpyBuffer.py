import numpy as np
from PySide2.QtCore import * 
from PySide2.QtWidgets import *
from PySide2.QtQml import *
from PySide2.QtGui import *
from PySide2.QtQuick import *

class NumpyBuffer(QObject):
    update = Signal()
    filenameChanged = Signal()
    rowsChanged = Signal()
    colsChanged = Signal()

    def __init__(self, parent=None):
        QObject.__init__(self, parent)
        self._filename = ''
        self._arr = np.asarray([[]], dtype=np.float32)

    @Property(int, notify=colsChanged)
    def channels(self):
        return self._arr.shape[0]

    @Property(int, notify=rowsChanged)
    def length(self):
        return self._arr.shape[1]

    @Property(QUrl, notify=filenameChanged)
    def filename(self):
        return self._filename


    @filename.setter
    def setFilename(self, val):
        if self._filename == val:
            return

        self._filename = val

        try:
            arr = np.load(self._filename.toLocalFile())
            self._arr = arr['arr_0'].astype(np.float32).transpose()
            
            
            #self._arrs = [QByteArray(self._arr[..., x].tobytes()) for x in range(self.cols)]
            self._arrs = QByteArray(self._arr.tobytes())
            
            self.rowsChanged.emit()
            self.colsChanged.emit()
            self.update.emit()
        except:
            print('failed')
            pass
        


    @Property(QByteArray, notify=update)
    def array(self):
        return self._arrs
