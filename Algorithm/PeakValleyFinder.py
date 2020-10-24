from .Processor import Processor
from .Common import *
from .Algorithm import *
import numpy as np
import inspector

class PeakValleyFinder(Processor):
    def __init__(self, lookback=16):
        Processor.__init__(self)
        self._result = Result()

    def __call__(self, data):
        peaks, valleys = inspector.hcpeakvalley(data, 16)
        for p in peaks:
            self._result.point(p, data[p])

        for p in valleys:
            self._result.point(p, data[p])

    @property
    def result(self):
        return self._result
