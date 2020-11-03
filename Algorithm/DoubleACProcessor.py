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

class Smoother(object):

    def same_note(x, y):
        if x != None and y != None:
            return abs(x-y)<0.5
        else:
            return False

    def __init__(self):
        self._curNote = None
        self._cntOn = 0
        self._chance = 2
        self._cntOff = 2

    def feed(self, note):
        event = 'no'
        if self._curNote == None and note==None:
            self._cntOff+=1
        elif self._curNote == None and note!=None:
            self._cntOn = 1
            self._curNote = note
            self._chance = 0
            event = 'check'
            
        elif note != None and Smoother.same_note(self._curNote, note):
            self._cntOff = 0
            self._cntOn+=1
            self._chance = 2
            self._curNote = note
            if self._cntOn == 3:
                event = 'onset'
            elif self._cntOn > 3:
                event = 'sustain'
        elif self._curNote !=None and not Smoother.same_note(note, self._curNote):
            self._chance -= 1
            
            if self._chance < 0:
                self._cntOff = 0
                self._curNote = None
                if self._cntOn >= 3:
                    event = 'offset'
            elif self._cntOn > 3:
                event = 'sustain'

        return event, 0 if self._curNote==None else self._curNote
        



@Algorithm('DoubleAC')
class DoubleACProcessor(Processor):
    def __init__(self, x_offset=0, rate=32000, size=1024, dtype=np.float32, **argv):
        Processor.__init__(self)
        self._buf = Buffer(size, dtype=np.float32)
        self._result = Result()
        self._samples = 0
        self._rate = rate
        self._x_offset = x_offset
        self._sm = Smoother()

    def __call__(self, data):
        self._buf.push(data)

        r = np.zeros(500+1, dtype=np.float32)
        r[32:] = auto_correlation(self._buf.array, 32, 500, 256)
        
        p, v = hcpeakvalley(r)
        
        
        if len(v) >= 2 and v[0] < 32 and v[-1]>245:
            

            
            v = np.asarray(v)
            vv = np.argsort(r[v])
            
            delay = None
            for i in range(1, len(v)):
                rnk = np.where(vv == i)[0]
                if rnk < 3:
                    delay = v[i]
                    break

            if delay is not None:
                """
                import matplotlib.pyplot as plt
                plt.figure()
                plt.plot(r)
                plt.scatter(p, r[p])
                print(p)
                print(v)
                plt.scatter(v, r[v])
                plt.show()
                """
                
                
                

                freq = self._rate / delay
                note = freq_to_note_noround(freq)
                event, res = self._sm.feed(note)
                if event == 'onset' or event == 'sustain':

                    self._result.rect(self._x_offset+self._samples, np.min(data), self._x_offset+self._samples+len(data), np.max(data),
                        note_name(round(res)))
                
            

        self._samples += len(data)

    @property
    def result(self):
        return self._result
        