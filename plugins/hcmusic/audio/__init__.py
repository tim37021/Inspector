from .AudioDevice import AudioInputDevice, AudioOutputDevice

qmlexports = [
    {'class': AudioInputDevice, 'exportName': 'AudioInputDevice', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
    {'class': AudioOutputDevice, 'exportName': 'AudioOutputDevice', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
]
