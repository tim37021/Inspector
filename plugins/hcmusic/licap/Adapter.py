from .LiCAPDevice import *
from PySide2.QtCore import *
from enum import Enum
from Buffer import BufferedSource

class LiCAPDevice(BufferedSource):
    portChanged = Signal()
    deviceTypeChanged = Signal()
    recordingChanged = Signal()
    rateChanged = Signal()
    
    @QEnum
    class Variant(Enum):
        LiCAPv1, LiCAP_R_DVT = range(2)

    def __init__(self, parent=None):
        BufferedSource.__init__(self, 1, 1, False, parent)
        self._port = ''
        self._inst = None
        self._deviceType = 0
        self._recording = False

        QApplication.instance().aboutToQuit.connect(lambda: self.stop())


    @Property(int, notify=rateChanged)
    def rate(self):
        return 32000

    @Property(str, notify=portChanged)
    def port(self):
        return self._port
    
    @port.setter
    def setPort(self, val):
        if self._port != val:
            self._port = val
            self.reopen()

            self.portChanged.emit()

    @Property(int, notify=deviceTypeChanged)
    def deviceType(self):
        return self._deviceType

    
    @deviceType.setter
    def setDeviceType(self, val):
        if self._deviceType != val:
            self._deviceType = val
            self.reopen()
            self.deviceTypeChanged.emit()


    @Property(bool, notify=recordingChanged)
    def recording(self):
        return self._recording
    
    @recording.setter
    def setRecording(self, val):
        if self._recording != val:
            self._recording = val
            
            if self._inst is not None:
                if self._recording:
                    self._inst.start()
                else:
                    self._inst.stop()

            self.recordingChanged.emit()

    def reopen(self):

        if self._inst is not None:
            self._inst.stop()

        if self._deviceType == 0:
            self._inst = LiCAPv1(self._port, self.callback)
            self.init(44100, 6)
        elif self._deviceType == 1:
            self._inst = LiCAP_R_EVT(self._port, self.callback)
            self.init(44100, 8)

        if self._recording:
            self._inst.start()

    def callback(self, buf):
        # to [channel, length]
        buf = buf.transpose()
        self.consume(buf)