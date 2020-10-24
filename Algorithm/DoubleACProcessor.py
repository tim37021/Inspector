from Processor import Processor
from Common import *
from Algorithm import *
import numpy as np

class DoubleACProcessor(Processor):
    def __init__(self, size=1024, dtype=np.float32):
        DoubleACProcessor.__init__(self)
        self._buf = Buffer(size, dtype=np.float32)
        self._result = Result()
        self._samples = 0

    def __call__(self, data):
        self._buf.push(data)
        self._samples += len(data)

    @property
    def result():
        return self._result
        