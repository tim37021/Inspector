from .Adapter import QLiCAPv1, QLiCAPv2

qmlexports = [
    {'class': QLiCAPv1, 'exportName': 'LiCAPv1', 'uri': 'hcmusic.licap', 'major': 1, 'minor': 0},
    {'class': QLiCAPv2, 'exportName': 'LiCAPv2', 'uri': 'hcmusic.licap', 'major': 1, 'minor': 0},
]
