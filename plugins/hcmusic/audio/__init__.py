from .AudioDevice import AudioInputDevice, AudioOutputDevice
from .AudioDevice import AudioDiscoveryModelProvider


qmlexports = [
    {'class': AudioDiscoveryModelProvider, 'exportName': 'AudioDiscoveryModelProvider', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
    {'class': AudioInputDevice, 'exportName': 'AudioInputDevice', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
    {'class': AudioOutputDevice, 'exportName': 'AudioOutputDevice', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
    {'class': AudioInputDevice, 'exportName': 'AudioInputDevice2', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
    {'class': AudioOutputDevice, 'exportName': 'AudioOutputDevice2', 'uri': 'hcmusic.audio', 'major': 1, 'minor': 0},
]
