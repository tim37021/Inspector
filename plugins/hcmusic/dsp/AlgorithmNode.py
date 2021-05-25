import PySide2.QtCore as QtCore
from PySide2.QtQml import VolatileBool
import PySide2.QtQuick as QtQuick
from PySide2.QtCore import Property, Signal, Slot
import numpy as np
from math import ceil, log2, sqrt
from statistics import mean

from .Node import EstimateNode, ProcessorNode, QtSignal1D
# from .Utils import freq_to_note_noround
from Algorithm.DoubleACProcessor import Smoother, freq_to_note_noround

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

    def __init__(self, parent=None):
        EstimateNode.__init__(self, parent)
        self._frequency = 0
        self._note = 0
        self._rate = 0
        self._min_lag = 32
        self._max_lag = 500
        self._window = 256
        self._threshold = 150000
        self._noteOnset = 0

        # Temporary select channel in algorithm nodes
        self._channel = 0 

        self._curNote = None
        self._smoother = Smoother()

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
        from cInspector import auto_correlation
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

        event, smoothed_note = self._smoother.feed(note)
        self._note = round(smoothed_note)
    
        if event == 'onset':
            self.onset.emit()
            self._noteOnset = self._note
        elif event == 'sustain':
            self.sustain.emit()
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


class PhaseWireCalc(ProcessorNode):
    windowSizeChanged = Signal()
    t1Changed = Signal()
    t2Changed = Signal()
    channelsChanged = Signal()
    samplerateChanged = Signal()
    frequencyChanged = Signal()
    calcFinished = Signal()
    channelUnitsChanged = Signal()
    inverseChanged = Signal()
    channelNameChanged = Signal()

    def __init__(self, parent=None):
        ProcessorNode.__init__(self, QtSignal1D, parent)
        # self._windowSize = 2000 # 20ms window for 10K sample rate
        self._windowSize = 100
        self._t1 = 0
        self._t2 = 0
        self._updated = False
        self._channels = [0, 1, 2, 3, 4, 5]
        self._inverse = [False, False, False, True, True, True]
        self._channelUnits  = ["v", "v", "v", "a", "a", "a"]
        self._samplerate = 10000
        self._frequency = 50
        self._channelName = [
            "P+", "Q+", "P-", "Q-", "P0", "Q0",
            "U+", "U-", "U0",
            "IP+", "IQ+", "IP-", "IQ-", "IP0", "IQ0",
            "pf+", "pf-", "pf0",
            "U1", "U2", "U3", "I1", "I2", "I3",
            "P1", "P2", "P3", "Q1", "Q2", "Q3"
        ]

    @Property("QVariantList", notify=channelNameChanged)
    def channelName(self):
        return self._channelName

    @channelName.setter
    def channelName(self, val):
        if self._channelName != val:
            self._channelName = val
            self.channelNameChanged.emit()

    @Property("QVariantList", notify=inverseChanged)
    def inverse(self):
        return self._inverse

    @inverse.setter
    def inverse(self, val):
        if self._inverse != val:
            self._inverse = val
            self.inverseChanged.emit()

    @Property("QVariantList", notify=channelUnitsChanged)
    def channelUnits(self):
        return self._channelUnits

    @channelUnits.setter
    def channelUnits(self, val):
        if self._channelUnits != val:
            self._channelUnits = val
            self.channelUnitsChanged.emit()

    @Property("QVariantList", notify=channelsChanged)
    def channels(self):
        return self._channels
    
    @channels.setter
    def channels(self, val):
        if self._channels != val:
            self._channels = val
            self.channelsChanged.emit()

            if self.completed:
                self.initialize()

            self.update(0, 0)


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
            self.initialize()

            if self._updated:
                self._output.update.emit(min(self._t1, self._t2), max(self._t1, self._t2))

    @Property(int, notify=samplerateChanged)
    def samplerate(self):
        return self._samplerate
    
    @samplerate.setter
    def samplerate(self, val):
        if self._samplerate != val:
            self._samplerate = val
            self.samplerateChanged.emit()

    @Property(int, notify=frequencyChanged)
    def frequency(self):
        return self._samplerate
    
    @frequency.setter
    def frequency(self, val):
        if self._frequency != val:
            self._frequency = val
            self.frequencyChanged.emit()
    
    @Slot()
    def refresh(self):
        self._output.update.emit(self._t1, self._t2)

    @Slot(int, int, result="QVariantList")
    def getReport(self, t1, t2):
        ret = []
        for i in range(len(self._channels)):
            sig = None
            if self._inverse[i]:
                sig = -1 * self._input.numpy_array[:, self._channels[i]]
            else:
                sig = self._input.numpy_array[:, self._channels[i]]
            ret.append({"name": "CH" + str(i + 1) + "[" + self._channelUnits[self._channels[i]] + "]", "v1": str(sig[t1]), "v2": str(sig[t2]), "v3": str(sig[t2] - sig[t1]) })
        
        for i in range(len(self._channelName)):
            ret.append({"name": self._channelName[i], "v1": str(self._output.numpy_array[t1, i]), "v2": str(self._output.numpy_array[t2, i]), "v3": str(self._output.numpy_array[t2, i] - self._output.numpy_array[t1, i])})
        return ret

    def update(self, offset, length):
        x = np.linspace(
            2*np.pi * self._frequency * self._t1/ self._samplerate,
            2*np.pi * self._frequency * self._t2/ self._samplerate,
            self._t2 - self._t1
        )
        cons = np.cos(x)
        sins = np.sin(x)
        ucos = []
        usin = []
        for i in range(self.input.channels):
            sig = None
            if self._inverse[i]:
                sig = -1 * self._input.numpy_array[min(self._t1, self._t2) : max(self._t1, self._t2), self._channels[i]]
            else:
                sig = self._input.numpy_array[min(self._t1, self._t2) : max(self._t1, self._t2), self._channels[i]]
            cosArr = sig * cons 
            sinArr = sig * sins

            window = np.ones(self._windowSize) / float(self._windowSize)

            ucos.append(np.convolve(cosArr, window, 'valid') * 2)
            usin.append(np.convolve(sinArr, window, 'valid') * 2)

        u1 = np.sqrt((np.square(ucos[self._channels[0]]) + np.square(usin[self._channels[0]])) / 2)
        u2 = np.sqrt((np.square(ucos[self._channels[1]]) + np.square(usin[self._channels[1]])) / 2)
        u3 = np.sqrt((np.square(ucos[self._channels[2]]) + np.square(usin[self._channels[2]])) / 2)

        i1 = np.sqrt((np.square(ucos[self._channels[3]]) + np.square(usin[self._channels[3]])) / 2)
        i2 = np.sqrt((np.square(ucos[self._channels[4]]) + np.square(usin[self._channels[4]])) / 2)
        i3 = np.sqrt((np.square(ucos[self._channels[5]]) + np.square(usin[self._channels[5]])) / 2)

        p1 = ucos[self._channels[0]]  * ucos[self._channels[3]] + usin[self._channels[0]] * usin[self._channels[3]]
        p2 = ucos[self._channels[1]]  * ucos[self._channels[4]] + usin[self._channels[1]] * usin[self._channels[4]]
        p3 = ucos[self._channels[2]]  * ucos[self._channels[5]] + usin[self._channels[2]] * usin[self._channels[5]]

        q1 = ucos[self._channels[0]] * usin[self._channels[3]] - usin[self._channels[0]] * ucos[self._channels[3]]
        q2 = ucos[self._channels[1]] * usin[self._channels[4]] - usin[self._channels[1]] * ucos[self._channels[4]]
        q3 = ucos[self._channels[2]] * usin[self._channels[5]] - usin[self._channels[2]] * ucos[self._channels[5]]
        
        uPosCos = (2 * ucos[0] - ucos[1] - ucos[2] - sqrt(3) * (usin[2] - usin[1])) / 6
        uPosSin = (2 * usin[0] - usin[1] - usin[2] - sqrt(3) * (ucos[1] - ucos[2])) / 6
        iPosCos = (2 * ucos[3] - ucos[4] - ucos[5] - sqrt(3) * (usin[5] - usin[4])) / 6
        iPosSin = (2 * usin[3] - usin[4] - usin[5] - sqrt(3) * (ucos[4] - ucos[5])) / 6

        uNegCos = (2 * ucos[0] - ucos[1] - ucos[2] - sqrt(3) * (usin[1] - usin[2])) / 6
        uNegSin = (2 * usin[0] - usin[1] - usin[2] - sqrt(3) * (ucos[2] - ucos[1])) / 6
        iNegCos = (2 * ucos[3] - ucos[4] - ucos[5] - sqrt(3) * (usin[4] - usin[5])) / 6
        iNegSin = (2 * usin[3] - usin[4] - usin[5] - sqrt(3) * (ucos[5] - ucos[4])) / 6
        
        uZeroCos = (ucos[0] + ucos[1] + ucos[2]) / (3 * sqrt(2))
        uZeroSin = (usin[0] + usin[1] + usin[2]) / (3 * sqrt(2))
        iZeroCos = (ucos[3] + ucos[4] + ucos[5]) / (3 * sqrt(2))
        iZeroSin = (usin[3] + usin[4] + usin[5]) / (3 * sqrt(2))

        pPos = 3 / 2 * (uPosCos * iPosCos + uPosSin * iPosSin)
        qPos = 3 / 2 * (uPosCos * iPosSin - uPosSin * iPosCos)

        pNeg = 3 / 2 * (uNegCos * iNegCos + uNegSin * iNegSin)
        qNeg = 3 / 2 * (uNegCos * iNegSin - uNegSin * iNegCos)

        pZero = 3 * (uZeroCos * iZeroCos + uZeroSin * iZeroSin)
        qZero = 3 * (uZeroSin * iZeroCos - uZeroCos * iZeroSin)

        uPos  = np.sqrt(3 / 2 * (np.square(uPosCos) + np.square(uPosSin)))
        uNeg  = np.sqrt(3 / 2 * (np.square(uNegCos) + np.square(uNegSin)))
        uZero = np.sqrt(3 * (np.square(uZeroCos) + np.square(uZeroSin)))

        iPPos  = pPos / (sqrt(3) * uPos)
        iQPos  = qPos / (sqrt(3) * uPos)
        iPNeg  = pNeg / (sqrt(3) * uNeg)
        iQNeg  = qNeg / (sqrt(3) * uNeg)
        iPZero = pZero / (sqrt(3) * uZero)
        iQZero = qZero / (sqrt(3) * uZero)

        pfPos  = pPos / (np.sqrt(np.square(pPos) + np.square(qPos)))
        pfNeg  = pNeg / (np.sqrt(np.square(pNeg) + np.square(qNeg)))
        pfZero = pZero / (np.sqrt(np.square(pZero) + np.square(qZero)))

        self._output.numpy_array[..., 0] = pPos
        self._output.numpy_array[..., 1] = qPos
        self._output.numpy_array[..., 2] = pNeg
        self._output.numpy_array[..., 3] = qNeg
        self._output.numpy_array[..., 4] = pZero
        self._output.numpy_array[..., 5] = qZero

        self._output.numpy_array[..., 6] = uPos
        self._output.numpy_array[..., 7] = uNeg
        self._output.numpy_array[..., 8] = uZero

        self._output.numpy_array[..., 9] = iPPos
        self._output.numpy_array[..., 10] = iQPos
        self._output.numpy_array[..., 11] = iPNeg
        self._output.numpy_array[..., 12] = iQNeg
        self._output.numpy_array[..., 13] = iPZero
        self._output.numpy_array[..., 14] = iQZero

        self._output.numpy_array[..., 15] = pfPos
        self._output.numpy_array[..., 16] = pfNeg
        self._output.numpy_array[..., 17] = pfZero

        self._output.numpy_array[..., 18] = u1
        self._output.numpy_array[..., 19] = u2
        self._output.numpy_array[..., 20] = u3

        self._output.numpy_array[..., 21] = i1
        self._output.numpy_array[..., 22] = i2
        self._output.numpy_array[..., 23] = i3

        self._output.numpy_array[..., 24] = p1
        self._output.numpy_array[..., 25] = p2
        self._output.numpy_array[..., 26] = p3

        self._output.numpy_array[..., 27] = q1
        self._output.numpy_array[..., 28] = q2
        self._output.numpy_array[..., 29] = q3

        self.calcFinished.emit()

        self._output.update.emit(min(self._t1, self._t2), max(self._t1, self._t2))

    def initialize(self):
        m = abs(self._t2 - self._t1)
        n = self._windowSize
        self._output.alloc(max(m, n) - min(m, n) + 1, 30)

    def _windowRMS(self, a, windowSize):
        a2 = np.power(a,2)
        window = np.ones(windowSize)/float(windowSize)
        return np.sqrt(np.convolve(a2, window, 'valid'))


class ReChannelNode(ProcessorNode):
    windowSizeChanged = Signal()
    channelChanged = Signal()
    inverseChanged = Signal()

    def __init__(self, parent=None):
        ProcessorNode.__init__(self, QtSignal1D, parent)
        self._windowSize = 2000 # 20ms window for 10K sample rate
        self._channel = [0, 1, 2, 3, 4, 5]
        self._inverse = [False, False, False, False, False, False]
        self._updated = False

    @Property("QVariantList", notify=inverseChanged)
    def inverse(self):
        return self._inverse

    @inverse.setter
    def inverse(self, val):
        if self._inverse != val:
            self._inverse = val
            self.inverseChanged.emit()

            if self.completed:
                self.update(0, self._input.length)

    @Property("QVariantList", notify=channelChanged)
    def channel(self):
        return self._channel

    @channel.setter
    def channel(self, val):
        if self._channel != val:
            self._channel = val
            self.channelChanged.emit()
            self.initialize()

            if self.completed:
                self.update(0, self._input.length)
    
    @Slot()
    def refresh(self):
        self._output.update.emit(0, self._input.length)

    def update(self, offset, length):
        if self._output.length != self._input.length or self._output.channels != self._input.channels:
            self.initialize()
        for index, c in enumerate(self._channel):
            if self._inverse[index]:
                self._output.numpy_array[..., c] = self._input.numpy_array[:, index] * (-1)
            else:
                self._output.numpy_array[..., c] = self._input.numpy_array[:, index]

        self._output.update.emit(0, self._input.length)

    def initialize(self):
        self._output.alloc(self._input.length, self._input.channels)
