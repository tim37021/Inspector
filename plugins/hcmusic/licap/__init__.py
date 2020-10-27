from .Adapter import LiCAPDevice

qmlexports = [
    {'class': LiCAPDevice, 'exportName': 'LiCAPDevice', 'uri': 'hcmusic.licap', 'major': 1, 'minor' : 0}
]