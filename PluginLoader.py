class PluginLoader(object):
    def __init__(self, path):
        self._path = path

    def install(self):
        pass

    @property
    def uri(self):
        return self._path

class QMLPluginLoader(PluginLoader):
    def __init__(self, path):
        PluginLoader.__init__(self, path)

class PythonPluginLoader(PluginLoader):
    def __init__(self, path):
        PluginLoader.__init__(self, path)

    def install(self):
        from PySide2.QtQml import qmlRegisterType
        import importlib

        pkg = importlib.import_module(self._path)
        for export in pkg.qmlexports:
            qmlRegisterType(
                export['class'],
                export['uri'],
                export['major'],
                export['minor'],
                export['exportName']
            )

def scan_plugins(folder, prefix=''):
    import os
    from os import listdir

    ret = []
    for fn in listdir(folder):
        if os.path.isdir(os.path.join(folder, fn)):
            if os.path.isfile(os.path.join(folder, fn, '__init__.py')):
                ret.append(PythonPluginLoader('%s.%s'%(prefix, fn)))
            elif os.path.isfile(os.path.join(folder, fn, 'qmldir')):
                ret.append(QMLPluginLoader('%s.%s'%(prefix, fn)))
            else:
                ret += scan_plugins(os.path.join(folder, fn), fn)

    return ret