from .Processor import Processor
from .Common import *
from .Algorithm import *
import numpy as np
import cInspector

@Algorithm(name='hcPeakValley')
class PeakValleyFinder(Processor):
    def __init__(self, x_offset=0, lookback=16, **argv):
        Processor.__init__(self)
        self._result = Result()
        self._inst = cInspector.hcPeakValley()
        self._x_offset = x_offset
        self._lastSlice = None

    def __call__(self, data):
        base = self._inst.samples
        peaks, valleys = self._inst(data)
        for p in peaks:
                self._result.point(self._x_offset+p, data[p-base] if p-base>=0 else self._lastSlice[p-base])

        for p in valleys:
            self._result.point(self._x_offset+p, data[p-base] if p-base>=0 else self._lastSlice[p-base])

        self._lastSlice = data

    @property
    def result(self):
        return self._result
