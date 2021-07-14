from os import write
import PySide2.QtCore as QtCore
from PySide2.QtQml import VolatileBool
import PySide2.QtQuick as QtQuick
from PySide2.QtCore import Property, Signal, Slot
import numpy as np
import pandas as pd
from numpy.core.fromnumeric import argmax
from scipy.signal import find_peaks, find_peaks_cwt
from math import ceil, log2, nan, sqrt
from statistics import mean

from .Node import EstimateNode, ProcessorNode, QtSignal1D, Node, Signal1D
# from .Utils import freq_to_note_noround

def best_lag_analyze(data, min_lag ,max_lag, threshold):
    from cInspector import hcpeakvalley
    ps, vs = hcpeakvalley(data)

    if len(ps) == 0 or len(vs) == 0:
        return -1
    
    if(vs[0] <= min_lag):
        vs = vs[1:]

    argmin = -1
    argmax = -1
    lag = -1

    for i in range(len(vs)):
        if(argmin == -1 or data[vs[argmin]] > data[vs[i]]):
            argmin = i
    for i in range(len(ps)):
        if(argmax == -1 or data[ps[argmax]] < data[ps[i]]):
            argmax = i

    if(argmin == -1 or argmax == -1):
        return -1

    min_val = data[vs[argmin]]
    signal_range = data[ps[argmax]] - min_val

    if(signal_range > threshold):
        for i in range(len(vs)):
            cur = vs[i]
            if(cur > min_lag * 2 and data[cur] - min_val < signal_range*0.15) :
                return vs[i]   # return the first valley that is in tolerance with min_val  
    
    return -1


class Amplitude(EstimateNode):
    amplitudeChanged = Signal()
    offsetChanged = Signal()
    windowSizeChanged = Signal()
    channelChanged = Signal()

    def __init__(self, parent=None):
        EstimateNode.__init__(self, parent)
        self._offset = 50
        self._amplitude = 0
        self._windowSize = 256

        # Temporary select channel in algorithm nodes
        self._channel = 0

    @Property(int, notify=amplitudeChanged)
    def amplitude(self):
        return self._amplitude

    @Property(int, notify=channelChanged)
    def channel(self):
        return self._channel

    @channel.setter
    def channel(self, val):
        if self._channel != val:
            self._channel = val
            self.channelChanged.emit()

    @Property(int, notify=windowSizeChanged)
    def windowSize(self):
        return self._windowSize

    @windowSize.setter
    def windowSize(self, val):
        if self._windowSize != val:
            self._windowSize = val
            self.windowSizeChanged.emit()
    
    @Property(int, notify=offsetChanged)
    def offset(self):
        return self._offset
    
    @offset.setter
    def offset(self, val):
        if self._offset != val:
            self._offset = val
            self.offsetChanged.emit()

    def update(self, offset, length):
        # from cInspector import auto_correlation
        # ac = np.zeros(shape=self._max_lag +1, dtype=np.float32)
        # ac[self._min_lag:] = auto_correlation(self._input.numpy_array.reshape(-1), self._min_lag, self._max_lag, self._window)

        # envelope = self.getEnvelope(self._input.numpy_array.reshape(-1), self._offset)
        envelope = self.getEnvelope(self._input.numpy_array[..., self._channel].reshape(-1), self._offset)
        self._amplitude = mean(envelope)
        self.amplitudeChanged
        # self._amplitude = amplitude(ac, self._min_lag)
        # self.amplitudeChanged.emit()

    def getEnvelope (self, inputSignal, intervalLength):
        # Taking the absolute value
        absoluteSignal = []
        for sample in inputSignal:
            absoluteSignal.append (abs (sample))
        # Peak detection
        outputSignal = []
        
        # peak 10 samples in absoluteSignal
        for baseIndex in range (intervalLength, len (absoluteSignal), intervalLength//10):
            maximum = 0
            for lookbackIndex in range (intervalLength):
                maximum = max (absoluteSignal [baseIndex - lookbackIndex], maximum)
            outputSignal.append (maximum)
        
        return outputSignal



class ChannelToChannelRMS(ProcessorNode):
    windowSizeChanged = Signal()
    channel1Changed = Signal()
    channel2Changed = Signal()
    t1Changed = Signal()
    t2Changed = Signal()


    def __init__(self, parent=None):
        ProcessorNode.__init__(self, QtSignal1D, parent)
        self._windowSize = 2000 # 20ms window for 10K sample rate
        self._channel1 = 0
        self._channel2 = 0
        self._t1 = 0
        self._t2 = 0
        self._updated = False

    @Property(int, notify=windowSizeChanged)
    def windowSize(self):
        return self._windowSize

    @windowSize.setter
    def windowSize(self, val):
        if self._windowSize != val:
            self._windowSize = val
            self.windowSizeChanged.emit()

            if self.completed:
                self.initialize()

    @Property(int, notify=channel1Changed)
    def channel1(self):
        return self._channel1

    @channel1.setter
    def channel1(self, val):
        if self._channel1 != val:
            self._channel1 = val
            self.channel1Changed.emit()

            if self.completed:
                self.initialize()
                self.update(0, abs(self._t2 - self._t1))

    @Property(int, notify=channel2Changed)
    def channel2(self):
        return self._channel2

    @channel2.setter
    def channel2(self, val):
        if self._channel2 != val:
            self._channel2 = val
            self.channel1Changed.emit()

            if self.completed:
                self.initialize()
                self.update(0, abs(self._t2 - self._t1))

    @Property(int, notify=t1Changed)
    def t1(self):
        return self._t1

    @t1.setter
    def t1(self, val):
        if self._t1 != val:
            self._t1 = val
            self.t1Changed.emit()

            if self._updated:
                self._output.update.emit(min(self._t1, self._t2), max(self._t1, self._t2))

    @Property(int, notify=t2Changed)
    def t2(self):
        return self._t2

    @t2.setter
    def t2(self, val):
        if self._t2 != val:
            self._t2 = val
            self.t2Changed.emit()

            if self._updated:
                self._output.update.emit(min(self._t1, self._t2), max(self._t1, self._t2))
    
    @Slot()
    def refresh(self):
        self._output.update.emit(self._t1, self._t2)

    def update(self, offset, length):
        signal1 = self._input.numpy_array[min(self._t1, self._t2) : max(self._t1, self._t2), self._channel1]
        signal2 = self._input.numpy_array[min(self._t1, self._t2) : max(self._t1, self._t2), self._channel2]
        subArr = np.subtract(signal1, signal2)
        
        squareArr = np.power(subArr, 2)
        window = np.ones(self._windowSize) / float(self._windowSize)
        print(squareArr.shape)
        print(window.shape)

        self._output.numpy_array[...] = np.sqrt(np.convolve(squareArr, window, 'valid'))[:-1].reshape(-1, 1)
        self._output.update.emit(min(self._t1, self._t2), max(self._t1, self._t2))

    def initialize(self):
        self._output.alloc(abs(self._t2 - self._t1), 1)

    def _windowRMS(a):
        a2 = np.power(a,2)
        window = np.ones(len(a))/float(len(a))
        return np.sqrt(np.convolve(a2, window, 'valid'))


class ChannelRMS(ProcessorNode):
    windowSizeChanged = Signal()
    channelChanged = Signal()
    t1Changed = Signal()
    t2Changed = Signal()

    def __init__(self, parent=None):
        ProcessorNode.__init__(self, QtSignal1D, parent)
        self._windowSize = 2000 # 20ms window for 10K sample rate
        self._channel = 0
        self._t1 = 0
        self._t2 = 0
        self._updated = False

    @Property(int, notify=windowSizeChanged)
    def windowSize(self):
        return self._windowSize

    @windowSize.setter
    def windowSize(self, val):
        if self._windowSize != val:
            self._windowSize = val
            self.windowSizeChanged.emit()

            if self.completed:
                self.initialize()

    @Property(int, notify=channelChanged)
    def channel(self):
        return self._channel

    @channel.setter
    def channel(self, val):
        if self._channel != val:
            self._channel = val
            self.channelChanged.emit()

            if self.completed:
                self.initialize()
                self.update(0, abs(self._t2 - self._t1))

    @Property(int, notify=t1Changed)
    def t1(self):
        return self._t1

    @t1.setter
    def t1(self, val):
        if self._t1 != val:
            self._t1 = val
            self.t1Changed.emit()
            self.initialize()

            if self._updated:
                self._output.update.emit(min(self._t1, self._t2), max(self._t1, self._t2))

    @Property(int, notify=t2Changed)
    def t2(self):
        return self._t2

    @t2.setter
    def t2(self, val):
        if self._t2 != val:
            self._t2 = val
            self.t2Changed.emit()
            self.initialize()

            if self._updated:
                self._output.update.emit(min(self._t1, self._t2), max(self._t1, self._t2))
    
    @Slot()
    def refresh(self):
        self._output.update.emit(self._t1, self._t2)

    def update(self, offset, length):
        for i in range(3):
            subArr = self._input.numpy_array[min(self._t1, self._t2) : max(self._t1, self._t2), i]
        
            squareArr = np.power(subArr, 2)
            window = np.ones(self._windowSize) / float(self._windowSize)

            self._output.numpy_array[..., i] = np.sqrt(np.convolve(squareArr, window, 'valid'))
        self._output.update.emit(min(self._t1, self._t2), max(self._t1, self._t2))

    def initialize(self):
        # self._output.alloc(max(abs(self._t2 - self._t1) - self._windowSize, self._windowSize), 1)
        m = abs(self._t2 - self._t1)
        n = self._windowSize
        self._output.alloc(max(m, n) - min(m, n) + 1, 3)

    def _windowRMS(a):
        a2 = np.power(a,2)
        window = np.ones(len(a))/float(len(a))
        return np.sqrt(np.convolve(a2, window, 'valid'))


class ChannelToChannelConv(ProcessorNode):
    windowSizeChanged = Signal()
    channel1Changed = Signal()
    channel2Changed = Signal()
    t1Changed = Signal()
    t2Changed = Signal()

    def __init__(self, parent=None):
        ProcessorNode.__init__(self, QtSignal1D, parent)
        self._windowSize = 2000 # 20ms window for 10K sample rate
        self._channel1 = 0
        self._channel2 = 0
        self._t1 = 0
        self._t2 = 0
        self._updated = False


    @Property(int, notify=windowSizeChanged)
    def windowSize(self):
        return self._windowSize

    @windowSize.setter
    def windowSize(self, val):
        if self._windowSize != val:
            self._windowSize = val
            self.windowSizeChanged.emit()

            if self.completed:
                self.initialize()

    @Property(int, notify=channel1Changed)
    def channel1(self):
        return self._channel1

    @channel1.setter
    def channel1(self, val):
        if self._channel1 != val:
            self._channel1 = val
            self.channel1Changed.emit()

            if self.completed:
                self.initialize()
                self.update(0, abs(self._t2 - self._t1))

    @Property(int, notify=channel2Changed)
    def channel2(self):
        return self._channel2

    @channel2.setter
    def channel2(self, val):
        if self._channel2 != val:
            self._channel2 = val
            self.channel1Changed.emit()

            if self.completed:
                self.initialize()
                self.update(0, abs(self._t2 - self._t1))

    @Property(int, notify=t1Changed)
    def t1(self):
        return self._t1

    @t1.setter
    def t1(self, val):
        if self._t1 != val:
            self._t1 = val
            self.t1Changed.emit()
            self.initialize()

            if self._updated:
                self._output.update.emit(min(self._t1, self._t2), max(self._t1, self._t2))

    @Property(int, notify=t2Changed)
    def t2(self):
        return self._t2

    @t2.setter
    def t2(self, val):
        if self._t2 != val:
            self._t2 = val
            self.t2Changed.emit()
            self.initialize()

            if self._updated:
                self._output.update.emit(min(self._t1, self._t2), max(self._t1, self._t2))
    
    @Slot()
    def refresh(self):
        self._output.update.emit(self._t1, self._t2)

    def update(self, offset, length):
        signal1 = self._input.numpy_array[min(self._t1, self._t2) : max(self._t1, self._t2), self._channel1]
        signal2 = self._input.numpy_array[min(self._t1, self._t2) : max(self._t1, self._t2), self._channel2]
        convArr = np.multiply(
            signal1,
            signal2,
        )
        rms = self._windowRMS(convArr, self._windowSize)

        # self._output.numpy_array[...] = convArr.reshape(-1, 1)
        self._output.numpy_array[...] = rms.reshape(-1, 1)
        self._output.update.emit(min(self._t1, self._t2), max(self._t1, self._t2))

    def initialize(self):
        # self._output.alloc(abs(self._t2 - self._t1) - self._windowSize, 1)
        m = abs(self._t2 - self._t1)
        n = self._windowSize
        self._output.alloc(max(m, n) - min(m, n) + 1, 1)

    def _windowRMS(self, a, windowSize):
        a2 = np.power(a,2)
        window = np.ones(windowSize)/float(windowSize)
        return np.sqrt(np.convolve(a2, window, 'valid'))


