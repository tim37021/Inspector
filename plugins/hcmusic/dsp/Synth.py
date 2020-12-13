import numpy as np
from .Node import Signal1D, Node, QtSignal1D
from PySide2.QtCore import Property, Signal, Slot
from math import floor


class SineSynth(Node):
    frequencyChanged = Signal()
    rateChanged = Signal()
    amplitudeChanged = Signal()
    lengthChanged = Signal()
    phaseChanged = Signal()
    outputChanged = Signal()

    def __init__(self, parent=None):
        Node.__init__(self, parent)
        self._phase = 0
        self._frequency = 1
        self._length = 1024
        self._rate = 44100
        self._amplitude = 1
        self._output = QtSignal1D()

    @Property(float, notify=phaseChanged)
    def phase(self):
        return self._phase

    @phase.setter
    def phase(self, val):
        if self._phase != val:
            self._phase = val
            self.phaseChanged.emit()

    @Property(float, notify=amplitudeChanged)
    def amplitude(self):
        return self._amplitude

    @amplitude.setter
    def amplitude(self, val):
        if self._amplitude != val:
            self._amplitude = val
            self.amplitudeChanged.emit()

    @Property(int, notify=rateChanged)
    def rate(self):
        return self._rate

    @rate.setter
    def rate(self, val):
        if self._rate != val:
            self._rate = val
            self.rateChanged.emit()

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

    @Property(float, notify=frequencyChanged)
    def frequency(self):
        return self._frequency

    @frequency.setter
    def frequency(self, val):
        if self._frequency != val and val > 0:
            self._frequency = val
            self.frequencyChanged.emit()

    @Property(Signal1D, final=True, notify=outputChanged)
    def output(self):
        return self._output

    def initialize(self):
        self._output.alloc(self._length, 1)
        # since we haven't generate any thing, don't emit
        # self._output.update.emit(0, self._length)

    @Slot()
    def synth(self):
        T = 1 / self._frequency
        start = T * self._phase
        end = start + self._length / self._rate
        t = np.linspace(start, end, self._length)
        self._phase = end / T - floor(end / T)
        self.phaseChanged.emit()
        self._output.numpy_array[..., 0] = self._amplitude * np.sin(2 * np.pi * self._frequency * t)
        self._output.update.emit(0, self._length)
