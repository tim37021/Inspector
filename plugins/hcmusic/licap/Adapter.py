from PySide2.QtCore import Signal, Property
from PySide2.QtWidgets import QApplication
from ..dsp.Node import QtSignal1D, Node, Signal1D
from .LiCAPDevice import LiCAPv1


"""
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

    def stop(self):
        if self._inst is not None:
            self._inst.stop()

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
"""


class QLiCAPv1(Node):
    """LiCAP DSP Style

    TODO: Check device exists
    """
    outputChanged = Signal()
    activeChanged = Signal()
    bufferLengthChanged = Signal()
    portChanged = Signal()
    error = Signal(str, arguments=['message'])

    def __init__(self, parent=None):
        Node.__init__(self, parent)
        self._output = QtSignal1D()
        self._active = False
        self._bufferLength = 256
        self._acc = 0
        self._port = ''
        self._device = None
        QApplication.instance().aboutToQuit.connect(lambda: self.closeDevice())

    @Property(Signal1D, notify=outputChanged)
    def output(self):
        return self._output

    @Property(bool, notify=activeChanged)
    def active(self):
        return self._active

    @active.setter
    def active(self, val):
        if self._active != val:
            self._active = val
            self.activeChanged.emit()

            if self.completed and self._active:
                self.openDevice()
            if self.completed and not self._active:
                self.closeDevice()

    @Property(str, notify=portChanged)
    def port(self):
        return self._port

    @port.setter
    def port(self, val):
        if self._port != val:
            self._port = val
            self.portChanged.emit()

            if self.completed and self._active:
                self.openDevice()

    @Property(int, notify=bufferLengthChanged)
    def bufferLength(self):
        return self._bufferLength

    @bufferLength.setter
    def bufferLength(self, val):
        if self._bufferLength != val:
            self._bufferLength = val
            self.bufferLengthChanged.emit()

            if self.completed:
                raise Exception('Changing bufferLength on the fly is not support')

    def openDevice(self):
        self.closeDevice()
        self._device = LiCAPv1(self._port, self._update)
        if not self._device.start():
            self._active = False
            self.activeChanged.emit()
            self.error.emit('Cannot open device %s' % self._port)

    def closeDevice(self):
        if self._device is not None:
            self._device.stop()
            self._device = None

    def _update(self, buf):
        self._output.numpy_array[self._acc: self._acc+len(buf), :] = buf
        self._acc += len(buf)
        if self._acc >= self._bufferLength:
            self._acc = 0
            self._output.update.emit(0, self._bufferLength)

    def initialize(self):
        self._output.alloc(self._bufferLength, 6)
        if self._active:
            self.openDevice()
