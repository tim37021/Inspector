import PySide2.QtCore as QtCore
from PySide2.QtCore import Property, Signal, Qt, QModelIndex
from serial.tools.list_ports import comports


class VCPDiscoveryModel(QtCore.QAbstractListModel):
    """Discovery Virtual COM Port

    Reference: https://pyserial.readthedocs.io/en/latest/tools.html
    Quick Query
    python -m serial.tools.list_ports -v

    TODO Export more info to QML
    """
    DeviceRole = Qt.UserRole + 1
    UsbVendorIdRole = Qt.UserRole + 2
    UsbProductIdRole = Qt.UserRole + 3

    idFilterChanged = Signal()
    runningChanged = Signal()

    def __init__(self, parent=None):
        QtCore.QAbstractListModel.__init__(self, parent)
        self._timer = QtCore.QTimer()
        self._idFilter = QtCore.QRegExp(r'\d\d\d\d:\d\d\d\d')
        self._running = False
        self._entries = []

        self._timer.timeout.connect(self._update)

    @Property(QtCore.QRegExp, notify=idFilterChanged)
    def idFilter(self):
        return self._idFilter

    @idFilter.setter
    def idFilter(self, val):
        if self._idFilter != val:
            self._idFilter = val
            self.idFilterChanged.emit()

    @Property(bool)
    def running(self):
        return self._running

    @running.setter
    def running(self, val):
        if self._running != val:
            self._running = val
            self.runningChanged.emit()

            if self._running:
                self._timer.start(1000)
            else:
                self._timer.stop()

    def rowCount(self, parent=QtCore.QModelIndex()):
        if parent.isValid():
            return 0
        return len(self._entries)

    def data(self, index, role=Qt.DisplayRole):
        if 0 <= index.row() < self.rowCount() and index.isValid():
            item = self._entries[index.row()]
            if role == VCPDiscoveryModel.UsbVendorIdRole:
                return item.vid
            elif role == VCPDiscoveryModel.UsbProductIdRole:
                return item.pid
            elif role == VCPDiscoveryModel.DeviceRole:
                return item.device

    def roleNames(self):
        roles = dict()
        roles[VCPDiscoveryModel.DeviceRole] = b"device"
        roles[VCPDiscoveryModel.UsbVendorIdRole] = b"usbVendorId"
        roles[VCPDiscoveryModel.UsbProductIdRole] = b"usbProductId"
        return roles

    def _update(self):
        cps = comports()
        cps = [cp for cp in cps if self._idFilter.exactMatch('%04x:%04x' % (cp.vid, cp.pid))]
        en = self._entries.copy()
        for cp in cps:
            if cp not in self._entries:
                self.beginInsertRows(QModelIndex(), self.rowCount(), self.rowCount())
                self._entries.append(cp)
                self.endInsertRows()
            else:
                en.remove(cp)

        self.remove(en)

    def remove(self, cps):
        for cp in cps:
            idx = self._entries.index(cp)
            self.beginRemoveRows(QModelIndex(), idx, idx)
            self._entries.remove(cp)
            self.endRemoveRows()
