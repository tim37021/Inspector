from .Node import Node, Signal1D, Storage, RingBuffer
from .Synth import SineSynth

qmlexports = [
    {'class': Node, 'exportName': 'Node', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
    {'class': Signal1D, 'exportName': 'Signal1D', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
    {'class': Storage, 'exportName': 'Storage', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
    {'class': RingBuffer, 'exportName': 'RingBuffer', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
    {'class': SineSynth, 'exportName': 'SineSynth', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
]
