import numpy as np
from PySide2.QtCore import * 
from PySide2.QtWidgets import *
from PySide2.QtQml import *
from PySide2.QtGui import *
from PySide2.QtQuick import *

import json

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
    plt.axis('off')
    axes = plt.gca()

    # change this line for y axis control
    axes.set_ylim([5000, 0])

    extent = (bins[0],bins[-1]*1024,freqs[-1],freqs[0])
    im = plt.imshow(arr2D,aspect='auto',extent = extent,interpolation="none")
    plt.gca().invert_yaxis()
    # comment this line
    plt.tight_layout(pad=0)

    # flush draw commands
    fig.canvas.draw()

    # Now we can save it to a numpy array.
    data = np.frombuffer(fig.canvas.tostring_rgb(), dtype=np.uint8)
    data = data.reshape(fig.canvas.get_width_height()[::-1] + (3,))

    plt.close()

    # transpose to BGR
    return data[..., ::-1]

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
        #import licapdsp
        data = np.frombuffer(data, dtype=np.float32)
        corr = np.zeros(max_lag - min_lag + 1, dtype=np.float32)
        for x in range(min_lag, max_lag+1):
            corr[x-min_lag] = np.sum(np.abs(data[-window_size:] - data[-window_size-x: -x]) / window_size)
        return corr.tolist()

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