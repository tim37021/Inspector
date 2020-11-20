from .Processor import Processor
from .Common import *
from .Algorithm import *
import numpy as np
import cInspector

class OnsetDetector(object):
    def __init__(self):
        self._inst = cInspector.hcPeakValley()

    def __call__(self, buf):
        pass

    def _fit(self, x, y):
        A = np.vstack((x, np.ones(len(x)))).T
        return np.linalg.lstsq(A, y, rcond=None)[0]

@Algorithm(name='OnsetDetector')
class OnsetDetector(Processor):
    def __init__(self, x_offset=0, lookback=16, **argv):
        Processor.__init__(self)
        self._result = Result()
        self._inst = cInspector.hcPeakValley(base_samples=x_offset)
        self._lastSlice = None

        self._lastPoints = []
        self._lastPointsY = []
        self._state = 'unvoiced'
        self._lastValue = 50

    def _fit(self, x, y):
        A = np.vstack((x, np.ones(len(x)))).T
        return np.linalg.lstsq(A, y, rcond=None)[0]

    def __call__(self, data):
        base = self._inst.samples
        peaks, valleys = self._inst(data)
        
        for p in peaks:
            y_ = data[p-base] if p-base>=0 else self._lastSlice[p-base]
            #self._result.point(x_, y_)
            self._lastPoints.append(p)
            self._lastPointsY.append(y_)

        for p in valleys:
            y_ = data[p-base] if p-base>=0 else self._lastSlice[p-base]
           # self._result.point(x_, y_)
            self._lastPoints.append(p)
            self._lastPointsY.append(y_)
        
        vps = np.asarray(self._lastPoints)
        mask = (self._inst.samples - vps) < 512
        vps = vps[mask]
        vpsy = np.asarray(self._lastPointsY)[mask]

        m, c = self._fit(vps, vpsy)

        l = m * vps + c
        val = np.mean(np.abs(l - vpsy))
        
        print(val)
        if val > self._lastValue * 2 and val > 70:
            print('GG')
            print(val)
            #if self._state == 'unvoiced':
            x_ = self._inst.samples - len(data)
            self._result.rect(x_, data.min(), x_+len(data), data.max(), 'onset')
            self._state = 'voiced'
        elif val < 10:#self._lastValue * 0.8:
            if self._state == 'voiced':
                x_ = self._inst.samples - len(data)
                self._result.rect(x_, data.min(), x_+len(data), data.max(), 'offset')
            self._state = 'unvoiced'

        self._lastPoints = vps.tolist()
        self._lastPointsY = vpsy.tolist()

        self._lastValue = val


        self._lastSlice = data

    @property
    def result(self):
        return self._result
