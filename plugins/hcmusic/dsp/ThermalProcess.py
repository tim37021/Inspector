from os import write
import PySide2.QtCore as QtCore
from PySide2.QtQml import VolatileBool
import PySide2.QtQuick as QtQuick
from PySide2.QtCore import Property, Signal, Slot, QUrl
import numpy as np
import pandas as pd
from numpy.core.fromnumeric import argmax
from scipy.signal import find_peaks, find_peaks_cwt
from math import ceil, log2, nan, sqrt
from statistics import mean

from .Node import EstimateNode, ProcessorNode, QtSignal1D, Node, Signal1D

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
        self._t2 = 1000
        self._updated = False
        self._channels = [0, 1, 2, 3, 4, 5]
        self._inverse = [False, False, False, False, False, False]
        self._channelUnits  = ["v", "v", "v", "a", "a", "a"]
        self._samplerate = 10000
        self._frequency = 50
        self._channelName = [
            "P+", "Q+", "P-", "Q-", "P0", "Q0",
            "U+", "U-", "U0",
            "IP+", "IQ+", "IP-", "IQ-", "IP0", "IQ0",
            "pf+", "pf-", "pf0",
            "U1", "U2", "U3", "I1", "I2", "I3",
            "P1", "P2", "P3", "Q1", "Q2", "Q3",
            "I+", "I-", "I0", "U-sig", "I-sig", "P-sig", "Q-sig"
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

        iPos = np.sqrt(np.square(iPPos) + np.square(iQPos))
        iNeg = np.sqrt(np.square(iPNeg) + np.square(iQNeg))
        iZero = np.sqrt(np.square(iPZero) + np.square(iQZero))

        uSig = (u1 + u2 + u3) / 3
        iSig = (i1 + i2 + i3) / 3
        pSig = (p1 + p2 + p3) / 3
        qSig = (q1 + q2 + q3) / 3

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

        self._output.numpy_array [..., 30] = iPos
        self._output.numpy_array [..., 31] = iNeg
        self._output.numpy_array [..., 32] = iZero

        self._output.numpy_array [..., 33] = uSig
        self._output.numpy_array [..., 34] = iSig
        self._output.numpy_array [..., 35] = pSig
        self._output.numpy_array [..., 36] = qSig

        self.calcFinished.emit()

        self._output.update.emit(min(self._t1, self._t2), max(self._t1, self._t2))

    def initialize(self):
        m = abs(self._t2 - self._t1)
        n = self._windowSize
        self._output.alloc(max(m, n) - min(m, n) + 1, 37)

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

class ThermalReportNode(Node):
    inputChanged = Signal()
    templatePathChanged = Signal()
    typeChanged = Signal()

    def __init__(self, parent=None):
        Node.__init__(self, parent)
        self._input = None
        self._samplerate = 10000
        self._template_path = ""
        self._type = "VDE"
        self._date = ""
        self._time = ""
        self._faultType = "3 phase fault"
        self._baseInfo = {
            "date": "",
            "time": "",
            "faultType": "3 phase fault",
            "voltageDepth": "0.15",
            "dipDuration": "1000"
        }

    @Property(Signal1D, notify=inputChanged)
    def input(self):
        return self._input

    @input.setter
    def input(self, val):
        if self._input != val:
            self._input = val
            self.inputChanged.emit()

    @Property(str, notify=typeChanged)
    def type(self):
        return self._type
    
    @type.setter
    def type(self, val):
        if self._type != val:
            self._type = val
            self.typeChanged.emit()

    @Property(str, notify=templatePathChanged)
    def templatePath(self):
        return self._template_path

    @templatePath.setter
    def templatePath(self, val):
        if self._template_path != val:
            self._template_path = val
            self.templatePathChanged.emit()


    def _getTargetTime(self, sig):
        peaks, _ = find_peaks(sig, height=50)
        return peaks

    def _getTargetTime2(self, sig, trigger_val = 1000):
        # diffSig = np.abs(np.diff(sig, 2))
        # peaks, val =find_peaks(diffSig, height=100)
        mask1 = (sig[:-1] < trigger_val) & (sig[1:] > trigger_val)
        mask2 = (sig[:-1] > trigger_val) & (sig[1:] < trigger_val)
        peaks = np.flatnonzero(mask1 | mask2) + 1
        print(peaks)
        # print(val)
        return peaks

    def _getStable(self, channel):
        return np.median(self._input.numpy_array[..., channel])

    def _getActivePowerRisingTime(self, t2, p = 1):
        reactValue = self._getStable(0) * (p - 0.1)
        for i in range(t2, len(self._input.numpy_array[..., 0])):
            if self._input.numpy_array[..., 0][i] >= reactValue:
                return i
        return None

    def _getActiveCurrentRisingTime(self, t2, p = 1):
        reactValue = self._getStable(9) * (p - 0.1)
        for i in range(t2, len(self._input.numpy_array[..., 9])):
            if self._input.numpy_array[..., 9][i] >= reactValue:
                return i
        return None

    def _getReactPowerRisingTime(self, t2, q = 0):
        reactDelta = np.max(self._input.numpy_array[..., 1]) - np.min(self._input.numpy_array[..., 1])
        for i in range(t2, len(self._input.numpy_array[..., 1])):
            if self._input.numpy_array[..., 1][i] <= reactDelta * 0.1 or self._input.numpy_array[..., 1][i] >= reactDelta * 0.1:
                return i
        return None

    def _getReactCurrentRisingTime(self, t2, q = 0):
        reactDelta = np.max(self._input.numpy_array[..., 10]) - np.min(self._input.numpy_array[..., 10])
        for i in range(t2, len(self._input.numpy_array[..., 10])):
            if self._input.numpy_array[..., 10][i] <= reactDelta * 0.1 or self._input.numpy_array[..., 10][i] >= reactDelta * 0.1:
                return i
        return None

    def _vdeMergeCells(self, worksheet, data, merge_format):
        keys = data.keys()
        worksheet.merge_range(0, 0, 0, 5, keys[0])
        
        for i in range(data.shape[1]):
            startRow = 2
            check_for_nan = data[keys[i]].isnull()
            try:
                for j in range(3, data.shape[0] + 4 ):
                    if not check_for_nan[j - 2]:
                        # print(rpExcel[keys[i]][j])
                        if(j - 2 - startRow >= 0):
                            worksheet.merge_range(startRow - 1, i, j - 2, i, data[keys[i]][startRow - 2], merge_format)
                        else:
                            worksheet.write(startRow - 1, i, data[keys[i]][startRow - 2], merge_format)
                        startRow = j
            except:
                pass
            worksheet.set_column(0, data.shape[1], 20)
        
        for i in range(1, data.shape[1]):
            worksheet.write(data.shape[0], i, data[keys[i]][data.shape[0] - 1], merge_format)

        for j in range(2, data.shape[0]):
            worksheet.write(j, len(keys) - 1, data[keys[len(keys) - 1]][j - 1], merge_format)
        
        worksheet.merge_range(32, 0, 39, 0, data[keys[0]][31], merge_format)
        worksheet.merge_range(0, 6, 1, 6, "Measured value", merge_format)

    def _bdewMergeCells(self, worksheet, data, merge_format):
        keys = data.keys()
        worksheet.merge_range(0, 0, 0, 5, keys[0])
        
        for i in range(data.shape[1]):
            startRow = 2
            check_for_nan = data[keys[i]].isnull()
            try:
                for j in range(3, data.shape[0] + 6 ):
                    if not check_for_nan[j - 2]:
                        if(j - 2 - startRow >= 0):
                            worksheet.merge_range(startRow - 1, i, j - 2, i, data[keys[i]][startRow - 2], merge_format)
                        else:
                            worksheet.write(startRow - 1, i, data[keys[i]][startRow - 2], merge_format)
                        startRow = j
            except:
                pass
            worksheet.set_column(0, data.shape[1], 20)

        worksheet.write(data.shape[0], 1, data[keys[1]][data.shape[0] - 1], merge_format)
        worksheet.write(data.shape[0], 2, data[keys[2]][data.shape[0] - 1], merge_format)

        for j in range(2, data.shape[0] + 1):
            worksheet.write(j, len(keys) - 1, data[keys[len(keys) - 1]][j - 1], merge_format)

        worksheet.merge_range(79, 3, 80, 3, data[keys[3]][78], merge_format)
        worksheet.merge_range(79, 4, 80, 4, data[keys[4]][78], merge_format)
        worksheet.merge_range(79, 5, 80, 5, data[keys[5]][78], merge_format)
        worksheet.merge_range(76, 0, 80, 0, data[keys[0]][75], merge_format)
        worksheet.merge_range(0, 6, 1, 6, "Measurement", merge_format)

    def _vdeReport(self):
        ret = {}
        # peaks = self._getTargetTime(self._input.numpy_array[..., 7])
        peaks = self._getTargetTime2(self._input.numpy_array[..., 0])
        if len(peaks) != 2:
            return ret
        t1 = peaks[0]
        t2 = peaks[1]
        ret["V1"] = self._baseInfo.get("date", "2021/6/18")
        ret["V2"] = self._baseInfo.get("time", "00:00:00")
        ret["V3"] = self._baseInfo.get("faultType", "3 phase fault")
        ret["V4"] = self._baseInfo.get("voltageDepth", "0.15")
        ret["V5"] = self._baseInfo.get("dipDuration", "1000")
        ret["V6"] = t1
        ret["V7"] = t2
        ret["V8"] = t2 - t1
        ret["V9"] = np.average(self._input.numpy_array[..., 33][int(t1 + 0.1 * self._samplerate): int(t2)])
        ret["V10"] = np.average(self._input.numpy_array[..., 6][int(t1 + 0.1 * self._samplerate): int(t2)])
        ret["V11"] = np.average(self._input.numpy_array[..., 7][int(t1 + 0.1 * self._samplerate): int(t2)])
        ret["V12"] = np.average(self._input.numpy_array[..., 33][200: t1])
        ret["V13"] = np.average(self._input.numpy_array[..., 30][int(t1 - 0.5 * self._samplerate): int(t1 - 0.1 * self._samplerate)])
        ret["V14"] = np.average(self._input.numpy_array[..., 35][int(max(t1 - 10 * self._samplerate, 0)): int(t1)])
        ret["V15"] = np.average(self._input.numpy_array[..., 0] [int(max(t1 - 10 * self._samplerate, 0)): int(t1)])
        ret["V16"] = np.average(self._input.numpy_array[..., 36][int(max(t1 - 10 * self._samplerate, 0)): int(t1)])
        ret["V17"] = np.average(self._input.numpy_array[..., 1] [int(max(t1 - 10 * self._samplerate, 0)): int(t1)])
        ret["V18"] = np.average(self._input.numpy_array[..., 15][int(max(t1 - 10 * self._samplerate, 0)): int(t1)])
        ## Get U1 U2 U3 variation
        u = []
        u.append(self._input.numpy_array[..., 18][int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])
        u.append(self._input.numpy_array[..., 19][int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])
        u.append(self._input.numpy_array[..., 20][int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])

        u1Diff = np.max(u[0]) - np.min(u[0])
        u2Diff = np.max(u[1]) - np.min(u[1])
        u3Diff = np.max(u[2]) - np.min(u[2])

        max_diff = argmax([u1Diff, u2Diff, u3Diff])
        ret["V19"] = np.average(u[max_diff])
        ret["V20"] = np.average(self._input.numpy_array[..., 6][int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])
        ret["V21"] = np.average(self._input.numpy_array[..., 7][int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])

        ret["V22"] = self._input.numpy_array[..., 21][int(t1 + 0.06 * self._samplerate)]
        ret["V23"] = self._input.numpy_array[..., 22][int(t1 + 0.06 * self._samplerate)]
        ret["V24"] = self._input.numpy_array[..., 23][int(t1 + 0.06 * self._samplerate)]

        ret["V25"] = self._input.numpy_array[..., 21][int(t1 + 0.1 * self._samplerate)]
        ret["V26"] = self._input.numpy_array[..., 22][int(t1 + 0.1 * self._samplerate)]
        ret["V27"] = self._input.numpy_array[..., 23][int(t1 + 0.1 * self._samplerate)]

        ret["V28"] = np.average(self._input.numpy_array[..., 35][int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])
        ret["V29"] = np.average(self._input.numpy_array[..., 0] [int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])

        ret["V30"] = np.average(self._input.numpy_array[..., 33][int(t2 + 3 * self._samplerate): int(t2 + 10 * self._samplerate)])
        ret["V31"] = np.average(self._input.numpy_array[..., 35][int(t2 + 3 * self._samplerate): int(t2 + 10 * self._samplerate)])
        ret["V32"] = np.average(self._input.numpy_array[..., 0] [int(t2 + 3 * self._samplerate): int(t2 + 10 * self._samplerate)])

        ret["V33"] = (self._getActivePowerRisingTime(t2) - t2) / self._samplerate
        ret["V34"] = np.average(self._input.numpy_array[..., 36][int(t2 + 3 * self._samplerate): int(t2 + 10 * self._samplerate)])
        ret["V35"] = np.average(self._input.numpy_array[..., 1] [int(t2 + 3 * self._samplerate): int(t2 + 10 * self._samplerate)])

        ret["V36"] = (self._getReactPowerRisingTime(t2) - t2) / self._samplerate
        ret["V37"] = "Yes"

        return ret

    def _bdewReport(self):
        ret = {}
        # peaks = self._getTargetTime(self._input.numpy_array[..., 7])
        peaks = self._getTargetTime2(self._input.numpy_array[..., 0])
        if len(peaks) != 2:
            return ret
        t1 = peaks[0]
        t2 = peaks[1]
        ret["B1"] = self._baseInfo.get("date", "2021/6/18")
        ret["B2"] = self._baseInfo.get("time", "00:00:00")
        ret["B3"] = self._baseInfo.get("faultType", "symmetry grid fault")
        ret["B4"] = self._baseInfo.get("voltageDepth", "0.")
        ret["B5"] = self._baseInfo.get("dipDuration", "1000")
        ret["B6"]  = "N/A"
        ret["B7"]  = "N/A"
        ret["B8"]  = "N/A"
        ret["B9"]  = "N/A"
        ret["B10"] = "N/A"
        ret["B11"] = t1
        ret["B12"] = t2
        ret["B13"] = "N/A"
        ret["B14"] = t2 - t1
        ret["B15"] = np.average(self._input.numpy_array[..., 33] [int(max(t1 - 60 * self._samplerate, 0)): int(t1)]) - np.average(self._input.numpy_array[..., 33] [int(max(t1 + 0.1 * self._samplerate, 0)): int(t2)])
        ret["B16"] = np.average(self._input.numpy_array[..., 6] [int(max(t1 - 60 * self._samplerate, 0)): int(t1)]) - np.average(self._input.numpy_array[..., 6] [int(max(t1 + 0.1 * self._samplerate, 0)): int(t2)])
        ret["B17"] = np.average(self._input.numpy_array[..., 7] [int(max(t1 - 60 * self._samplerate, 0)): int(t1)]) - np.average(self._input.numpy_array[..., 7] [int(max(t1 + 0.1 * self._samplerate, 0)): int(t2)])
        
        ret["B18"] = "N/A"
        ret["B19"] = "N/A"
        ret["B20"] = "N/A"
        ret["B21"] = "N/A"
        
        ret["B22"] = np.average(self._input.numpy_array[..., 33] [int(200): int(t1)])
        ret["B23"] = np.average(self._input.numpy_array[..., 6] [int(200): int(t1)])
        ret["B24"] = np.average(self._input.numpy_array[..., 7] [int(200): int(t1)])
        ret["B25"] = np.average(self._input.numpy_array[..., 6] [int(max(t1 - 0.5 * self._samplerate, 0)): int(max(t1 - 0.1 * self._samplerate, 0))])
        ret["B26"] = np.average(self._input.numpy_array[..., 6] [int(max(t1 - 1 * self._samplerate, 0)): int(t1)])
        ret["B27"] = np.average(self._input.numpy_array[..., 7] [int(max(t1 - 1 * self._samplerate, 0)): int(t1)])

        ret["B28"] = np.average(self._input.numpy_array[..., 30][int(t1 - 0.5 * self._samplerate): int(t1 - 0.1 * self._samplerate)])
        ret["B29"] = np.average(self._input.numpy_array[..., 10] [200: int(t1)])
        ret["B30"] = np.average(self._input.numpy_array[..., 10][int(t1 - 1 * self._samplerate): int(t1)])
        ret["B31"] = np.average(self._input.numpy_array[..., 12][int(t1 - 1 * self._samplerate): int(t1)])

        ret["B32"] = np.average(self._input.numpy_array[..., 9] [int(t1 - 1 * self._samplerate): int(t1)])

        ret["B33"] = np.average(self._input.numpy_array[..., 35][int(t1 - 10 * self._samplerate): int(t1)])
        ret["B34"] = np.average(self._input.numpy_array[..., 35][int(t1 - 2 * self._samplerate): int(t1)])
        ret["B35"] = np.average(self._input.numpy_array[..., 0] [int(t1 - 0.5 * self._samplerate): int(t1 - 0.1 * self._samplerate)])

        ret["B36"] = np.average(self._input.numpy_array[..., 10] [int(t1 - 0.5 * self._samplerate): int(t1 - 0.1 * self._samplerate)])
        ret["B37"] = "N/A"

        ret["B38"] = "?"
        ret["B39"] = "?"

        ret["B40"] = "?"
        ret["B41"] = "?"

        ret["B42"] = "?"
        ret["B43"] = "?"

        ## Get U1 U2 U3 variation
        u = []
        u.append(self._input.numpy_array[..., 18][int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])
        u.append(self._input.numpy_array[..., 19][int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])
        u.append(self._input.numpy_array[..., 20][int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])

        u1Diff = np.max(u[0]) - np.min(u[0])
        u2Diff = np.max(u[1]) - np.min(u[1])
        u3Diff = np.max(u[2]) - np.min(u[2])

        max_diff = argmax([u1Diff, u2Diff, u3Diff])
        ret["B44"] = np.average(u[max_diff])

        ret["B45"] = np.average(self._input.numpy_array[..., 6] [int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])
        ret["B46"] = np.average(self._input.numpy_array[..., 7] [int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])

        ret["B47"] = np.average(self._input.numpy_array[..., 10] [int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])
        ret["B48"] = np.average(self._input.numpy_array[..., 12] [int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])

        ret["B49"] = np.average(self._input.numpy_array[..., 30] [int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])
        ret["B50"] = np.average(self._input.numpy_array[..., 31] [int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])

        ret["B51"] = np.average(self._input.numpy_array[..., 0] [int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])
        ret["B52"] = np.average(self._input.numpy_array[..., 2] [int(t1 + 0.1 * self._samplerate): int(t2 - 0.02 * self._samplerate)])

        ret["B53"] = np.average(self._input.numpy_array[..., 21] [int(t1): int(t1 + 0.02 * self._samplerate)])
        ret["B54"] = np.average(self._input.numpy_array[..., 22] [int(t1): int(t1 + 0.02 * self._samplerate)])
        ret["B55"] = np.average(self._input.numpy_array[..., 23] [int(t1): int(t1 + 0.02 * self._samplerate)])
        
        ret["B56"] = self._input.numpy_array[..., 21] [int(t1 + 0.02 * self._samplerate)]
        ret["B57"] = self._input.numpy_array[..., 22] [int(t1 + 0.02 * self._samplerate)]
        ret["B58"] = self._input.numpy_array[..., 23] [int(t1 + 0.02 * self._samplerate)]

        ret["B59"] = self._input.numpy_array[..., 21] [int(t1 + 0.1 * self._samplerate)]
        ret["B60"] = self._input.numpy_array[..., 22] [int(t1 + 0.1 * self._samplerate)]
        ret["B61"] = self._input.numpy_array[..., 23] [int(t1 + 0.1 * self._samplerate)]

        ret["B62"] = self._input.numpy_array[..., 21] [int(t1 + 0.15 * self._samplerate)]
        ret["B63"] = self._input.numpy_array[..., 22] [int(t1 + 0.15 * self._samplerate)]
        ret["B64"] = self._input.numpy_array[..., 23] [int(t1 + 0.15 * self._samplerate)]

        ret["B65"] = self._input.numpy_array[..., 21] [int(t1 + 0.3 * self._samplerate)]
        ret["B66"] = self._input.numpy_array[..., 22] [int(t1 + 0.3 * self._samplerate)]
        ret["B67"] = self._input.numpy_array[..., 23] [int(t1 + 0.3 * self._samplerate)]

        ret["B68"] = self._input.numpy_array[..., 21] [int(t1 + 0.5 * self._samplerate)]
        ret["B69"] = self._input.numpy_array[..., 22] [int(t1 + 0.5 * self._samplerate)]
        ret["B70"] = self._input.numpy_array[..., 23] [int(t1 + 0.5 * self._samplerate)]

        ret["B71"] = self._input.numpy_array[..., 21] [int(t1 + 1 * self._samplerate)]
        ret["B72"] = self._input.numpy_array[..., 22] [int(t1 + 1 * self._samplerate)]
        ret["B73"] = self._input.numpy_array[..., 23] [int(t1 + 1 * self._samplerate)]

        ret["B74"] = np.average(self._input.numpy_array[..., 6] [int(t2 + 1 * self._samplerate): int(t2 + 10 * self._samplerate)])
        ret["B75"] = np.average(self._input.numpy_array[..., 35] [int(t2 + 1 * self._samplerate): int(t2 + 10 * self._samplerate)])
        ret["B76"] = "N/A"

        ret["B77"] = (self._getActiveCurrentRisingTime(t2) - t2) / self._samplerate
        ret["B78"] = (self._getReactCurrentRisingTime(t2) - t2) / self._samplerate

        return ret

    @Slot("QVariantMap")
    def setBaseInfo(self, info):
        self._baseInfo = info

    @Slot(result= "QVariantMap")
    def getBaseInfo(self):
        return self._baseInfo

    @Slot(QUrl)
    def calc(self, outputFile= "tests.xlsx"):
        from os import listdir
        from os.path import isfile, isdir, join
        import xlsxwriter
        templatePath = "./template"
        report = {}
        rpExcel = None
        if self._type == "VDE":
            report = self._vdeReport()
            rpExcel = pd.read_excel(join(templatePath, "VDE.xlsx"))
            writer = pd.ExcelWriter(outputFile.toLocalFile(), engine='xlsxwriter')

            for i in range(len(rpExcel["Measured value"])):
                if rpExcel["Measured value"][i] in report.keys():
                    rpExcel["Measured value"][i] = report[rpExcel["Measured value"][i]]
            
            rpExcel.to_excel(writer, sheet_name="Sheet1", index=False, engine="xlsxwriter")
            workbook = writer.book
            worksheet = writer.sheets["Sheet1"]
            merge_format = workbook.add_format({'align': 'center', 'valign': 'vcenter', 'border': 1})
            self._vdeMergeCells(worksheet, rpExcel, merge_format)
            writer.save()
        elif self._type == "BDEW":
            report = self._bdewReport()
            rpExcel = pd.read_excel(join(templatePath, "BDEW.xlsx"))
            writer = pd.ExcelWriter(outputFile.toLocalFile(), engine='xlsxwriter')

            for i in range(len(rpExcel["Measurement"])):
                if rpExcel["Measurement"][i] in report.keys():
                    rpExcel["Measurement"][i] = report[rpExcel["Measurement"][i]]
            
            rpExcel.to_excel(writer, sheet_name="Sheet1", index=False, engine="xlsxwriter")
            workbook = writer.book
            worksheet = writer.sheets["Sheet1"]
            merge_format = workbook.add_format({'align': 'center', 'valign': 'vcenter', 'border': 1})
            self._bdewMergeCells(worksheet, rpExcel, merge_format)
            writer.save()


        
