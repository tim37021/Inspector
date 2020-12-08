import pyaudio

p = pyaudio.PyAudio()


_lastTime = 0


def callback(in_data, frame_count, time_info, status):
    global _lastTime
    import time
    print(time.time() - _lastTime)
    print(len(in_data))
    _lastTime = time.time()
    return (None, pyaudio.paContinue)


for id in range(p.get_device_count()):
    dev_dict = p.get_device_info_by_index(id)
    for key, value in dev_dict.items():
        print(key, value)
stream = p.open(rate=44100, channels=1, format=pyaudio.paInt16, frames_per_buffer=512, input=True, output=False, stream_callback=callback)

print(stream.get_input_latency())
stream.start_stream()
while True:
    pass
