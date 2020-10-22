import numpy as np
from PySide2.QtCore import * 
from PySide2.QtWidgets import *
from PySide2.QtQml import *
from PySide2.QtGui import *
from PySide2.QtQuick import *
import threading

class SineSignal(QObject):
    """
        SineSignal
        An example buffer that changes with time and updates from separated thread
    """
    update = Signal()
    channelsChanged = Signal()
    lengthChanged = Signal()

    def __init__(self, parent=None):
        QObject.__init__(self, parent)
        self._filename = ''

        self._arr = np.zeros((6, 1024), dtype=np.float32)

        t = np.linspace(0, 1, 44100)
        self._arr[0, :] = np.sin(2*np.pi*441*(t[:1024]))
        self._arrs = QByteArray(self._arr.tobytes())

        self._running = True

        QApplication.instance().aboutToQuit.connect(lambda: self.stop())
        self._t = threading.Thread(target=self.update_array, args=())
        self._t.start()

    @Property(int, notify=channelsChanged)
    def channels(self):
        return 6

    @Property(int, notify=lengthChanged)
    def length(self):
        return self._arr.shape[1]

    @Property(QByteArray, notify=update)
    def array(self):
        return self._arrs

    def stop(self):
        self._running = False

    def update_array(self):
        import time
        x = 0
        while self._running:
            x+=0.1
            t = np.linspace(x, x+1, 44100)
            self._arr[0, :] = np.sin(2*np.pi*441*(t[:1024]))
            self._arrs = QByteArray(self._arr.tobytes())
            self.update.emit()

            time.sleep(0.1)
