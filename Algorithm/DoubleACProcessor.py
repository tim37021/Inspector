from .Processor import Processor
from .Common import *
from .Algorithm import *
import numpy as np
from cInspector import auto_correlation


@Algorithm('DoubleAC')
class DoubleACProcessor(Processor):
    def __init__(self, x_offset=0, rate=32000, size=1024, dtype=np.float32):
        Processor.__init__(self)
        self._buf = Buffer(size, dtype=np.float32)
        self._result = Result()
        self._samples = 0
        self._rate = rate
    def __call__(self, data):
        self._buf.push(data)

        r = np.zeros(500+1, dtype=np.float32)
        r[32:] = auto_correlation(self._buf.array, 32, 500, 256)
        ac = auto_correlation(r, 32, 500, 256)

        delay = np.argmin(ac) + 32

        print(self._rate / delay)
        

        self._samples += len(data)

    @property
    def result(self):
        return self._result
        