from .AudioDevice import AudioInputDevice, AudioInputDevice2, AudioOutputDevice, AudioOutputDevice2
from .AudioDevice import AudioDiscoveryModelProvider


qmlexports = [
    {'class': AudioDiscoveryModelProvider, 'exportName': 'AudioDiscoveryModelProvider', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
    {'class': AudioInputDevice, 'exportName': 'AudioInputDevice', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
    {'class': AudioInputDevice2, 'exportName': 'AudioInputDevice2', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
    {'class': AudioOutputDevice, 'exportName': 'AudioOutputDevice', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
    {'class': AudioOutputDevice2, 'exportName': 'AudioOutputDevice2', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
]
