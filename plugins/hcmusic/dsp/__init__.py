from .Node import Node, Signal1D, Storage, RingBuffer, FFT, AutoCorrelation
from .Synth import SineSynth
from .AlgorithmNode import Amplitude, ChannelToChannelRMS, ChannelRMS, ChannelToChannelConv
from .ThermalProcess import PhaseWireCalc, ReChannelNode, ThermalReportNode

qmlexports = [
    {'class': Node, 'exportName': 'Node', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
    {'class': Signal1D, 'exportName': 'Signal1D', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
    {'class': Storage, 'exportName': 'Storage', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
    {'class': RingBuffer, 'exportName': 'RingBuffer', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
    {'class': SineSynth, 'exportName': 'SineSynth', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
    {'class': FFT, 'exportName': 'FFT', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
    {'class': AutoCorrelation, 'exportName': 'AutoCorrelation', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
    {'class': Amplitude, 'exportName': 'Amplitude', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
    {'class': ChannelToChannelRMS, 'exportName': 'ChannelToChannelRMS', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
    {'class': ChannelRMS, 'exportName': 'ChannelRMS', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
    {'class': ChannelToChannelConv, 'exportName': 'ChannelToChannelConv', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
    {'class': PhaseWireCalc, 'exportName': 'PhaseWireCalc', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
    {'class': ReChannelNode, 'exportName': 'ReChannelNode', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0},
    {'class': ThermalReportNode, 'exportName': 'ThermalReportNode', 'uri': 'hcmusic.dsp', 'major': 1, 'minor': 0}
]
