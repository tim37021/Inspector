import numpy as np

def autocorrelation(data, min_lag, max_lag, window_size):
    """
        Auto correlation
        auto correlation with pure numpy approach
    """
    assert len(data) >= window_size, 'window size cannot be larger than input size'
    
    min_lag = min(len(data) - window_size, min_lag)
    max_lag = min(len(data) - window_size, max_lag)

    corr = np.zeros(max_lag - min_lag + 1, dtype=np.float32)
    for x in range(min_lag, max_lag+1):
        corr[x-min_lag] = np.sum(np.abs(data[-window_size:] - data[-window_size-x: -x]) / window_size)
    return corr

class Buffer(object):
    def __init__(self, size, dtype):
        self._buf = np.zeros(size, dtype=dtype)

    # append data and drop old
    def push(self, data):
        assert len(data.shape) == 1, 'Buffer class does not support multi-channel yet'
        self._buf[: -len(data)] = self._buf[len(data):]
        self._buf[-len(data):] = data

    @property
    def array(self):
        return self._buf
