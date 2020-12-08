from PySide2.QtCore import Signal, Property, QByteArray, Qt
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide2.QtWidgets import QApplication
from PySide2.QtGui import QImage
from PySide2.QtQuick import QQuickPaintedItem
from Buffer import RingBuffer, StorageBuffer, SignalOutput, BufferView
import PluginLoader
import os
import sys
sys.path.insert(0, 'plugins')
from AlgorithmPool import AlgorithmPool     # noqa: E402


class MyCanvas(QQuickPaintedItem):
    bufferChanged = Signal()

    def __init__(self, parent=None):
        QQuickPaintedItem.__init__(self, parent)
        self._buffer = None

    @Property(QByteArray, notify=bufferChanged)
    def buffer(self):
        return self._buffer

    @buffer.setter
    def buffer(self, buf):
        if self._buffer == buf:
            return

        self._buffer = buf
        self.bufferChanged.emit()

        self.update()

    def paint(self, painter):
        if self._buffer is not None:
            qimage = QImage(self._buffer, 640, 480, QImage.Format_BGR888)
            qimage = qimage.smoothScaled(int(self.width()), int(self.height()))
            painter.drawImage(0, 0, qimage)


class App(object):
    def __init__(self, argv):
        os.environ['QT_SCALE_FACTOR'] = '0'
        QApplication.setAttribute(Qt.AA_UseDesktopOpenGL)
        QApplication.setAttribute(Qt.AA_EnableHighDpiScaling)
        QApplication.setOrganizationName('hcmusic')
        self._argv = argv

    def run(self):
        # Create an instance of the application
        # QApplication MUST be declared in global scope to avoid segmentation
        # fault
        app = QApplication(self._argv)

        # Create QML engine
        engine = QQmlApplicationEngine()

        plugins = PluginLoader.scan_plugins('plugins')
        # install all
        for p in plugins:
            p.install()
            print('Plugin %s loaded' % p.uri)

        qmlRegisterType(MyCanvas, 'MyCanvas', 1, 0, 'MyCanvas')
        qmlRegisterType(AlgorithmPool, 'Algo', 1, 0, 'AlgorithmPool')
        qmlRegisterType(RingBuffer, 'inspector.dsp', 1, 0, 'RingBuffer')
        qmlRegisterType(StorageBuffer, 'inspector.dsp', 1, 0, 'StorageBuffer')
        qmlRegisterType(SignalOutput, 'inspector.dsp', 1, 0, 'SignalOutput')
        qmlRegisterType(BufferView, 'inspector.dsp', 1, 0, 'BufferView')

        engine.addImportPath('plugins')
        engine.addImportPath('imports')

        # Load the qml file into the engine
        engine.load('ui/main.qml')

        # Qml file error handling
        if not engine.rootObjects():
            sys.exit(-1)

        return app.exec_()


if __name__ == '__main__':
    app = App(sys.argv)

    sys.exit(app.run())
