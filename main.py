import os
import sys

from PySide2.QtCore import * 
from PySide2.QtWidgets import *
from PySide2.QtQml import *



if __name__ == '__main__':
    # Set the QtQuick Style
    # Acceptable values: Default, Fusion, Imagine, Material, Universal.
    os.environ['QT_QUICK_CONTROLS_STYLE'] = (sys.argv[1]
                                         if len(sys.argv) > 1 else "Default")

    os.environ['QT_SCALE_FACTOR'] = '0'
    QApplication.setAttribute(Qt.AA_UseDesktopOpenGL)
    # Create an instance of the application
    # QApplication MUST be declared in global scope to avoid segmentation fault
    app = QApplication(sys.argv)

    # Create QML engine
    engine = QQmlApplicationEngine()

    engine.addImportPath('plugins')
    engine.addImportPath('imports')

    # Load the qml file into the engine
    engine.load('main.qml')

    # Qml file error handling
    if not engine.rootObjects():
        sys.exit(-1)


    # engine.quit.connect(app.quit)
    # Unnecessary,
    # since QQmlEngine.quit has already connect to QCoreApplication.quit

    sys.exit(app.exec_())