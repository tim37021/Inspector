import numpy as np
import matplotlib.pyplot as plt
from matplotlib.mlab import window_hanning, specgram
import cv2

t = np.linspace(0, 1, 44100)
x = np.sin(2*np.pi*441*t)

plt.figure()
arr2D, freqs, bins = specgram(x, Fs=44100)
extent = (bins[0],bins[-1]*1024,freqs[-1],freqs[0])
im = plt.imshow(arr2D,aspect='auto',extent = extent,interpolation="none",
                    cmap = 'jet')
plt.gca().invert_yaxis()
plt.show()
plt.close()


cv2.imwrite('gg.png', im.get_array())