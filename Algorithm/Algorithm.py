class Result(object):
    def __init__(self):
        self._points = []
        self._rectangles = []

    def rect(self, x1, y1, x2, y2, text=''):
        self._rectangles.append({
            'x1': float(x1),
            'y1': float(y1),
            'x2': float(x2),
            'y2': float(y2),
            'text': str(text)
        })

    def point(self, x, y):
        self._points.append({
            'px': float(x),
            'py': float(y)
        })

    def serialize(self):
        return {
            'points': self._points,
            'rectangles': self._rectangles
        }

__algoList = {}

def Algorithm(name=None):
    def Algorithm_(class_arg):
        __algoList[name] = class_arg
        return class_arg
    return Algorithm_

def get_algorithm():
    return __algoList