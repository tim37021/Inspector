from .AudioDevice import AudioInputDevice, AudioInputDevice2, AudioInputDevice3,AudioOutputDevice, AudioOutputDevice2, AudioOutputDevice3
from .AudioDevice import AudioDiscoveryModelProvider, AudioDiscoveryModelProvider2


qmlexports = [
    {'class': AudioDiscoveryModelProvider, 'exportName': 'AudioDiscoveryModelProvider', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
    {'class': AudioDiscoveryModelProvider2, 'exportName': 'AudioDiscoveryModelProvider2', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
    {'class': AudioInputDevice, 'exportName': 'AudioInputDevice', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
    {'class': AudioInputDevice2, 'exportName': 'AudioInputDevice2', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
    {'class': AudioInputDevice3, 'exportName': 'AudioInputDevice3', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
    {'class': AudioOutputDevice, 'exportName': 'AudioOutputDevice', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
    {'class': AudioOutputDevice2, 'exportName': 'AudioOutputDevice2', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
    {'class': AudioOutputDevice3, 'exportName': 'AudioOutputDevice3', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
]
