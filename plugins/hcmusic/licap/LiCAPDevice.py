import threading

class LiCAPv1(object):
    def __init__(self, port, callback):
        self._port = port
        self._callback = callback
        self._recvbytes = 0
        self._last_timestamp = None
        self._bytes_rate = 0
        self._t = None

    def run(self):
        self._ser = serial.Serial(self._port)
        self._ser.stopbits = serial.STOPBITS_ONE
        self._ser.bytesize = serial.EIGHTBITS
        self._ser.parity = serial.PARITY_NONE
        #self._ser.open()
        self._ser.flushInput()

        while not self._stopped:
            buf = np.frombuffer(self.read(3072), np.uint16).astype(np.int32) * 65536 / 256
            self._callback(buf.reshape(-1, 6))
        
        self._ser.close()

    def read(self, num_bytes):
        buf = self._ser.read(num_bytes)
        self._recvbytes += len(buf)

        if self._last_timestamp == None:
            self._last_timestamp = time.time()

        elapsed_time = time.time() - self._last_timestamp
        if elapsed_time >= 1:
            self._bytes_rate = self._recvbytes / elapsed_time
            self._recvbytes = 0
            self._last_timestamp = time.time()

        return buf


    def start(self):
        self._t = threading.Thread(target=self.run, arg=())
        self._t.start()

    def stop(self):
        self._stopped = True
        if self._t is not None:
            self._t.join()

    @property
    def bytes_rate(self):
        return self._bytes_rate


class LiCAP_R_EVT(LiCAPv1):
    MAPPING = [0, 6, 5, 3, 4, 1, 2, 7]
    
    def run(self):
        self._ser = serial.Serial(self._port)
        self._ser.flushInput()
        
        while not self.stopped:
            buf = np.frombuffer(self.read(3072), np.uint16).astype(np.int32) * 65536 / 256
            buf = buf.reshape(-1, 8)[..., LiCAP_R_EVT.MAPPING]
            self._callback(buf)

        self._ser.close()