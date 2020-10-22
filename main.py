import os
import sys

from PySide2.QtCore import * 
from PySide2.QtWidgets import *
from PySide2.QtQml import *
from PySide2.QtGui import *
from PySide2.QtQuick import *

import numpy as np
from NumpyBuffer import NumpyBuffer
"""
from SineSignal import *
"""
from AlgorithmPool import AlgorithmPool

class MyCanvas(QQuickPaintedItem):
    bufferChanged = Signal()

    def __init__(self, parent=None):
        QQuickPaintedItem.__init__(self, parent)
        self._buffer = None

    @Property(QByteArray, notify=bufferChanged)
    def buffer(self):
        return self._buffer

    @buffer.setter
    def setBuffer(self, buf):
        if self._buffer == buf:
            return

        
        self._buffer = buf
        self.bufferChanged.emit()

        self.update()

    def paint(self, painter):
        if not self._buffer is None:
            qimage = QImage(self._buffer, 640, 480,
                            QImage.Format_BGR888 )
            qimage = qimage.smoothScaled(int(self.width()), int(self.height()))
            
            painter.drawImage(0, 0, qimage)
    


if __name__ == '__main__':
    # Set the QtQuick Style
    # Acceptable values: Default, Fusion, Imagine, Material, Universal.
    """
    os.environ['QT_QUICK_CONTROLS_STYLE'] = (sys.argv[1]
                                         if len(sys.argv) > 1 else "Default")
    """
    os.environ['QT_SCALE_FACTOR'] = '0'
    QApplication.setAttribute(Qt.AA_UseDesktopOpenGL)
    QApplication.setOrganizationName('hcmusic')
    # Create an instance of the application
    # QApplication MUST be declared in global scope to avoid segmentation fault
    app = QApplication(sys.argv)

    # Create QML engine
    engine = QQmlApplicationEngine()

    qmlRegisterType(MyCanvas, 'MyCanvas', 1, 0, 'MyCanvas')
    qmlRegisterType(NumpyBuffer, 'Buffer', 1, 0, 'NumpyBuffer')
    #qmlRegisterType(SineSignal, 'Buffer', 1, 0, 'SineSignal')
    qmlRegisterType(AlgorithmPool, 'Algo', 1, 0, 'AlgorithmPool')

    engine.addImportPath('plugins')
    engine.addImportPath('imports')

    # Load the qml file into the engine
    engine.load('ui/main.qml')

    # Qml file error handling
    if not engine.rootObjects():
        sys.exit(-1)


    # engine.quit.connect(app.quit)
    # Unnecessary,
    # since QQmlEngine.quit has already connect to QCoreApplication.quit

    sys.exit(app.exec_())