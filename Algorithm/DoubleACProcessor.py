from .Processor import Processor
from .Common import *
from .Algorithm import *
import numpy as np
from cInspector import auto_correlation, hcpeakvalley


def freq_to_note(freq):
    return int(np.round(np.log2(freq / 440) * 12) + 69)

def freq_to_note_noround(freq):
    return np.log2(freq / 440) * 12 + 69

def note_name(number):
    return ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'Bb', 'B'][number%12] + str(number//12 - 1)



@Algorithm('DoubleAC')
class DoubleACProcessor(Processor):
    def __init__(self, x_offset=0, rate=32000, size=1024, dtype=np.float32, **argv):
        Processor.__init__(self)
        self._buf = Buffer(size, dtype=np.float32)
        self._result = Result()
        self._samples = 0
        self._rate = rate
        self._x_offset = x_offset

    def __call__(self, data):
        self._buf.push(data)

        r = np.zeros(500+1, dtype=np.float32)
        r[32:] = auto_correlation(self._buf.array, 32, 500, 256)
        
        p, v = hcpeakvalley(r)
        
        
        if len(v) >= 2 and v[0] < 32:
            if not r[p].min() > r[v].max():

                """
                import matplotlib.pyplot as plt
                plt.figure()
                plt.plot(r)
                plt.scatter(p, r[p])
                plt.scatter(v, r[v])
                plt.show()
                """
                pass
                
            vv = np.argsort(r[v])
            
            delay = 500
            for i in range(1, len(v)):
                if np.where(vv == i)[0] < 3:
                    delay = v[i]
                    break
            
            freq = self._rate / delay

            self._result.rect(self._x_offset+self._samples, np.min(data), self._x_offset+self._samples+len(data), np.max(data),
                note_name(freq_to_note(freq)))
            

        self._samples += len(data)

    @property
    def result(self):
        return self._result
        