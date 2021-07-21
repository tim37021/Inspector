import math
import PySide2.QtCore as QtCore
import PySide2.QtQuick as QtQuick
from PySide2.QtCore import Property, Signal, Slot
import numpy as np
from scipy.signal import hilbert
from math import ceil, log2
from statistics import mean

from .Node import EstimateNode, ProcessorNode, QtSignal1D
# from .Utils import freq_to_note_noround
from Algorithm.DoubleACProcessor import Smoother, freq_to_note_noround
from cInspector import auto_correlation

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


class PitchTracker(EstimateNode):
    frequencyChanged = Signal()
    noteChanged = Signal()
    noteOnsetChanged = Signal()
    rateChanged = Signal()
    minLagChanged = Signal()
    maxLagChanged = Signal()
    windowSizeChanged = Signal()
    thresholdChanged = Signal()
    channelChanged = Signal()
    onset = Signal()
    offset = Signal()
    sustain = Signal()
    pitchbend = Signal(float, arguments=["pitchbend"])
    debugChanged = Signal()
    minNoteChanged = Signal()

    def __init__(self, parent=None):
        EstimateNode.__init__(self, parent)
        self._frequency = 0
        self._note = 0
        self._rate = 0
        self._min_lag = 32
        self._max_lag = 500
        self._min_note = 40
        self._window = 256
        self._threshold = 100000
        self._noteOnset = 0
        self._debug = False

        # Temporary select channel in algorithm nodes
        self._channel = 0 

        self._curNote = None
        self._smoother = Smoother()

    @Property(bool, notify=debugChanged)
    def debug(self):
        return self._debug
    
    @debug.setter
    def debug(self, val):
        if self._debug != val:
            self._debug = val
            self.debugChanged.emit()

    @Property(float, notify=minNoteChanged)
    def minNote(self):
        return self._min_note
    
    @minNote.setter
    def minNote(self, val):
        if self._min_note != val:
            self._min_note = val
            self.minLagChanged.emit()

    @Property(float, final=True, notify=frequencyChanged)
    def frequency(self):
        return self._frequency

    @Property(int, final=True, notify=noteChanged)
    def note(self):
        return self._note

    @Property(int, final=True, notify=noteOnsetChanged)
    def noteOnset(self):
        return self._noteOnset

    @Property(int, notify=rateChanged)
    def rate(self):
        return self._rate

    @rate.setter
    def rate(self, val):
        if self._rate != val:
            self._rate = val
            self.rateChanged.emit()

    @Property(int, notify=channelChanged)
    def channel(self):
        return self._channel

    @channel.setter
    def channel(self, val):
        if self._channel != val:
            self._channel = val
            self.channelChanged.emit()
    
    @Property(int, notify=minLagChanged)
    def minLag(self):
        return self._min_lag

    @minLag.setter
    def minLag(self, val):
        if self._min_lag != val:
            self._min_lag = val
            self.minLagChanged.emit()

    @Property(int, notify=maxLagChanged)
    def maxLag(self):
        return self._max_lag

    @maxLag.setter
    def maxLag(self, val):
        if self._max_lag != val:
            self._max_lag = val
            self.maxLagChanged.emit()

    @Property(int, notify=windowSizeChanged)
    def windowSize(self):
        return self._window

    @windowSize.setter
    def windowSize(self, val):
        if self._window != val:
            self._window = val
            self.windowSizeChanged.emit()

    @Property(int, notify=thresholdChanged)
    def threshold(self):
        return self._threshold

    @threshold.setter
    def threshold(self, val):
        if self._threshold != val:
            self._threshold = val
            self.thresholdChanged.emit()

    def update(self, offset, length):
        ac = np.zeros(shape=self._max_lag +1, dtype=np.float32)
        # ac[self._min_lag:] = auto_correlation(self._input.numpy_array.reshape(-1), self._min_lag, self._max_lag, self._window)
        ac[self._min_lag:] = auto_correlation(self._input.numpy_array[..., self._channel].reshape(-1), self._min_lag, self._max_lag, self._window)

        # Select the best responsive harmonic valley of auto correlation signal
        lag = best_lag_analyze(ac, self._min_lag, self._max_lag, self._threshold)

        freq = self._rate / lag

        if freq != None and freq != self._frequency:
            self._frequency = freq
            self.frequencyChanged.emit()
        
        # Pitch tracking process
        if(freq <= self._min_lag):
            note = None
        else:
            note = freq_to_note_noround(freq)
            # print(freq)
            if(note < self._min_note - 1):
                note = None
        # if self._debug:
        #     print(note)
        event, smoothed_note = self._smoother.feed(note)
        self._note = round(smoothed_note)
    
        if event == 'onset':
            self.onset.emit()
            self._noteOnset = self._note
            self.pitchbend.emit(smoothed_note - self._noteOnset)
        elif event == 'sustain':
            self.sustain.emit()
            self.pitchbend.emit(smoothed_note - self._noteOnset)
        elif event == 'offset':
            self.offset.emit()
    
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
        # envelope = self.getEnvelope(self._input.numpy_array[..., self._channel].reshape(-1), self._offset)
        analytic_signal = hilbert(self._input.numpy_array[..., self._channel].reshape(-1)) 
        envelope = np.abs(analytic_signal)
        self._amplitude = mean(envelope)
        self.amplitudeChanged.emit()
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


class AmplitudeNode(ProcessorNode):
    lengthChanged = Signal()
    channelsChanged = Signal()

    def __init__(self, parent=None):
        ProcessorNode.__init__(self, QtSignal1D, parent)
        self._channels = 0
        self._offset = 50
        self._length = 1024

    @Property(int, notify=channelsChanged)
    def channels(self):
        return self._channels

    @channels.setter
    def channels(self, val):
        if self._channels != val:
            self._channels = val
            self.channelsChanged.emit()

            if self.completed:
                self.initialize()

    @Property(int, notify=lengthChanged)
    def length(self):
        return self._length

    @length.setter
    def length(self, val):
        if self._length != val:
            self._length = val
            self.lengthChanged.emit()

            if self.completed:
                self.initialize()

    def update(self, offset, length):
        for i in range(self._channels):
            arr = self._input.numpy_array[offset: offset+length, i]
            oarr = self._output.numpy_array
            oarr[:-length, i] = oarr[length:, i]
            # analytic_signal = hilbert(arr) 
            # envelope = np.abs(analytic_signal)
            oarr[-length:, i] = np.linalg.norm(arr)
        self._output.update.emit(0, oarr.shape[0])

    def initialize(self):
        self._output.alloc(self._length, self._channels)
        self._output.update.emit(0, self._length)
