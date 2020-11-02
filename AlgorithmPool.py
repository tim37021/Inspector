import numpy as np

from PySide2.QtCore import * 
from PySide2.QtWidgets import *
from PySide2.QtQml import *
from PySide2.QtGui import *
from PySide2.QtQuick import *

import json
import cInspector

from Algorithm import get_algorithm

def plot_stft(arr, fs, nfft, noverlap):
    """Plot specgram of raw signal into numpy array

    Parameters:
    arr (Array-like): raw signal
    fs (int): frequency of the signal
    nfft (int): window size
    noverlap (int): overlap size

    Returns:
    numpy.ndarray: BGR888 raw image
    """

    import matplotlib
    matplotlib.use('agg')
    from matplotlib.mlab import window_hanning, specgram

    import matplotlib.pyplot as plt

    fig = plt.figure()

    arr2D, freqs, bins = specgram(arr, Fs=fs, NFFT=nfft, noverlap=noverlap, window=window_hanning)

    # comment this line
    #plt.axis('off')
    axes = plt.gca()

    # change this line for y axis control
    axes.set_ylim([1000, 0])

    extent = (bins[0],bins[-1]*1024,freqs[-1],freqs[0])
    im = plt.imshow(arr2D,aspect='auto',extent = extent,interpolation="none")
    plt.gca().invert_yaxis()

    # comment this line
    #plt.tight_layout(pad=0)
    # comment this line
    plt.colorbar()

    # flush draw commands
    fig.canvas.draw()

    # Now we can save it to a numpy array.
    data = np.frombuffer(fig.canvas.tostring_rgb(), dtype=np.uint8)
    data = data.reshape(fig.canvas.get_width_height()[::-1] + (3,))

    plt.close()

    # transpose to BGR
    return data[..., ::-1]

class Result(object):
    def __init__(self, points=[], rectangles=[]):
        self._points = points
        self._rectangles = rectangles    

    def rect(self, x1, y1, x2, y2, text=''):
        self._rectangles.append({
            'x1': float(x1),
            'y1': float(y1),
            'x2': float(x2),
            'y2': float(y2),
            'text': str(text)
        })

    def serialize(self):
        return {
            'points': self._points,
            'rectangles': self._rectangles
        }

    def __add__(self, op):
        return Result(self._points+op._points, self._rectangles + op._rectangles)

"""
QML API proposal

import Algorithm 1.0

AlgorithmPool {
    id: algo
}

algo.call(function_name: str, arr: QByteArray, args?: json) -> json

Examples:

Autocorrelation
algo.call('autocorrelation', arr.slice(mouseX, mouseX+1024).buffer)
"""
class AlgorithmPool(QObject):
    def __init__(self, parent=None):
        QObject.__init__(self, parent)

    @Slot(QByteArray, result='QVariantList')
    @Slot(QByteArray, int, int, int, result='QVariantList')
    def autocorrelation(self, data, min_lag=32, max_lag=500, window_size=500):
        data = np.frombuffer(data, dtype=np.float32)
        return cInspector.auto_correlation(data, min_lag, max_lag, window_size).tolist()

    @Slot(QByteArray, int, int, int, result=QByteArray)
    def stft(self, data, fs, nfft, noverlap):
        data = np.frombuffer(data, dtype=np.float32)
        data = plot_stft(data, fs, nfft, noverlap)
        return data.tobytes()

    @Slot(QByteArray, result='QVariantList')
    def fft(self, data):
        data = np.frombuffer(data, dtype=np.float32)
        data = np.abs(np.fft.fft(data))

        return data.tolist()

    @Slot(QByteArray, result=float)
    def hybridMethod(self, data):
        from matplotlib.mlab import specgram
        data = np.frombuffer(data, dtype=np.float32)

        arr2D, freqs, bins = specgram(data, Fs=32000, NFFT=1024, noverlap=512)

        return float(np.argmax(arr2D[1:, 0])+1) * 32000/1024

    @Slot(str, QByteArray, QJsonValue, result=QJsonValue)
    def launch(self, action, data, metadata=None):
        if not action in get_algorithm():
            return Result().serialize()
        
        algo = get_algorithm()[action]

        data = np.frombuffer(data, dtype=np.float32)

        start_x = 0
        metadata = metadata.toVariant()

        if 'selectArea' in metadata:
            rect = metadata['selectArea'][0]
            data = data[round(rect['x1']): round(rect['x2'])]
            start_x = round(rect['x1'])

        finder = algo(x_offset = start_x, rate=metadata['rate'])
        for i in range(0, len(data), 256):
            finder(data[i: i+256])

        return finder.result.serialize()
