import numpy as np
import matplotlib.pyplot as plt
import serial

ser = serial.Serial('COM3')

buf = ser.read(256 * 6 * 2 * 125)
x = np.frombuffer(buf, dtype=np.uint16).reshape(-1, 6).astype(np.int32) * 65536 / 256

plt.plot(x[:, 4])
plt.show()
