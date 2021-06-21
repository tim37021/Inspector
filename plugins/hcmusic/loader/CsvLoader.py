from PySide2.QtCore import QUrl, Signal, Property, Slot
from PySide2.QtWidgets import QApplication
from ..dsp.Node import QtSignal1D, Node, Signal1D

import numpy as np

class QCsvLoader(Node):
    filenameChanged = Signal()
    outputChanged = Signal()
    channelsChanged = Signal()

    def __init__(self, parent=None):
        Node.__init__(self, parent)
        self._header = []
        self._channelVUnits = []
        self._channelHUnits = []
        self._channelDates = []
        self._channelTimes = []
        self._channelHResolution = []
        self._channelHOffset = []
        self._channelNames = []
        self._channels = 0
        self._output = QtSignal1D()
        self._filename = ''

        QApplication.instance().aboutToQuit.connect(lambda: self.close())

    @Property(QUrl, notify=filenameChanged)
    def filename(self):
        return self._filename
    
    @Property(int, notify=channelsChanged)
    def channels(self):
        return self._channels

    @filename.setter
    def filename(self, val):
        if self._filename == val:
            return
        self._filename = val
        # self._extractFile(self._filename.toLocalFile())
        self.filenameChanged.emit()

    @Slot()
    def getHeader(self):
        self._extractHeader(self._filename.toLocalFile())

    @Slot()
    def run(self):
        self._extractFile(self._filename.toLocalFile())

    @Property(Signal1D, final=True, notify=outputChanged)
    def output(self):
        return self._output
    
    @Slot(int, result=str)
    def getChannelVUnit(self, ch):
        return self._channelVUnits[ch]

    @Slot(int , result=str)
    def getChannelHUnit(self, ch):
        return self._channelHUnits[ch]

    @Slot(int, result=str)
    def getChannelDate(self, ch):
        return self._channelDates[ch]

    @Slot(int, result=str)
    def getChannelTime(self, ch):
        return self._channelTimes[ch]

    @Slot(int, result=str)
    def getChannelHResolution(self, ch):
        return self._channelHResolution[ch]

    @Slot(int, result=str)
    def getChannelHOffset(self, ch):
        return self._channelHOffset[ch]

    @Slot(result="QVariantList")
    def getChannelVUnits(self):
        return self._channelVUnits

    @Slot(result="QVariantList")
    def getChannelHUnits(self):
        return self._channelHUnits
    
    @Slot(result="QVariantList")
    def getChannelNames(self):
        return self._channelNames

    @Slot()
    def refresh(self):
        self._output.update.emit(0, self._output.length)

    def close(self):
        pass

    def initialize(self):
        self._output.alloc(0, 6)

    def _extractHeader(self, filename):
        header = np.genfromtxt(filename, delimiter = ',', skip_header = 2, max_rows = 8, dtype = str) 
        # Get channels count
        self._channels = 0
        for block in header[0]:
            if "CH" in block:
                self._channels += 1
                self._channelNames.append(block)
        self.channelsChanged.emit()

        # Clear channel info
        self._channelVUnits = []
        self._channelHUnits = []
        self._channelDates = []
        self._channelTimes = []
        self._channelHResolution = []
        self._channelHOffset = []

        # Set channel info
        for i in range(1, self._channels + 1):
            self._channelDates.append(header[2][i])
            self._channelTimes.append(header[3][i])
            self._channelVUnits.append(header[4][i])
            self._channelHResolution.append(header[5][i])
            self._channelHOffset.append(header[6][i])
            self._channelHUnits.append(header[7][i])

    def _extractFile(self, filename):
        self._extractHeader(filename)

        # Load channel data
        buf =np.genfromtxt(filename, delimiter = ',', skip_header = 10, usecols = range(1, self._channels + 1))
        length, _ = buf.shape
        self._output.resize(length)
        self._output.numpy_array[:, :] = buf[:, :]

        if length > 0:
            self._output.update.emit(0, length)
