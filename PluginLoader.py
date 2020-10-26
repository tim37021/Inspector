


class PluginLoader(object):
    def __init__(self, path):
        self._path = path

    def install(self):
        from PySide2.QtQml import qmlRegisterType
        import importlib

        try:
            pkg = importlib.import_module(self._path)
            for export in pkg.qmlexports:
                qmlRegisterType(
                    export['class'],
                    export['uri'],
                    export['major'],
                    export['minor'],
                    export['exportName']
                )
        except:
            pass
            
    @property
    def uri(self):
        return self._path

def scan_plugins(folder, prefix=''):
    import os
    from os import listdir

    ret = []
    for fn in listdir(folder):
        if os.path.isdir(os.path.join(folder, fn)):
            if os.path.isfile(os.path.join(folder, fn, '__init__.py')):
                ret.append(PluginLoader('%s.%s'%(prefix, fn)))
            else:
                ret += scan_plugins(os.path.join(folder, fn), fn)

    return ret