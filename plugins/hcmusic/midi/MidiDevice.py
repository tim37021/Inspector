from PySide2.QtCore import Property, Signal, Slot, Qt, QModelIndex, QObject, QAbstractListModel
import mido


class MidiDeviceModel(QAbstractListModel):
    NameRole = Qt.UserRole + 1
    IndexRole = Qt.UserRole + 2

    def __init__(self, parent=None):
        QAbstractListModel.__init__(self, parent)

        self._entries = []

    def data(self, index, role=Qt.DisplayRole):
        if 0 <= index.row() < self.rowCount() and index.isValid():
            item = self._entries[index.row()]
            if role == MidiDeviceModel.NameRole:
                return item["name"]
            elif role == MidiDeviceModel.IndexRole:
                return item["index"]

    def rowCount(self, parent=QModelIndex()):
        if parent.isValid():
            return 0
        return len(self._entries)

    def roleNames(self):
        roles = dict()
        roles[MidiDeviceModel.NameRole] = b"name"
        roles[MidiDeviceModel.IndexRole] = b"deviceIndex"
        return roles

    # def update(self, index, name, maxInputChannels, defaultSampleRate):
    def update(self, index, name):
        # check if it exist in the lists
        idx = [i for i, x in enumerate(self._entries) if x['index'] == index]
        idx = idx[0] if len(idx) > 0 else None

        if idx is None:
            self.beginInsertRows(QModelIndex(), self.rowCount(), self.rowCount())
            self._entries.append({
                'index': index,
                'name': name,
            })
            self.endInsertRows()
        else:
            self._entries[idx]['name'] = name
            self.dataChanged.emit(QModelIndex(idx), QModelIndex(idx))

    def remove(self, indices):
        indices = sorted(indices)
        rm = 0

        for index in indices:
            self.beginRemoveRows(QModelIndex(), index-rm, index-rm)
            self._entries.pop(index-rm)
            self.endRemoveRows()

    @property
    def availableNames(self):
        return [x.name for x in self._entries]


class MidiDiscoveryModelProvider(QAbstractListModel):
    midiModelChanged = Signal()

    def __init__(self, parent=None):
        QAbstractListModel.__init__(self, parent)

        self._midiModel = MidiDeviceModel(self)
        self.refresh()

    @Property(QObject, final=True, notify=midiModelChanged)
    def midiDeviceModel(self):
        return self._midiModel

    @Slot()
    def refresh(self):
        idx = 0
        for dev_name in mido.get_output_names():
            self._midiModel.update(idx, dev_name)
            idx += 1

    @Slot(str, result=str)
    def find(self, part_name):
        """find device name(captial sensitive)
        """
        for dev_name in mido.get_output_names():
            if part_name in dev_name:
                return dev_name


class MidiOutputDevice(QObject):
    portNameChanged = Signal()
    openedChanged = Signal()

    def __init__(self, parent=None):
        QObject.__init__(self, parent)
        self._portName = ""
        self._opened = False
        self.outport = None

    @Property(bool, notify=openedChanged)
    def opened(self):
        return self._opened

    @Property(str, notify=portNameChanged)
    def portName(self):
        return self._portName

    @portName.setter
    def portName(self, val):
        if self._portName != val:
            # print(mido.get_output_names())
            # if val not in mido.get_output_names():
            #     return

            if self.outport is not None:
                self.outport.close()
                self._opened = False

            self._portName = val
            self.outport = mido.open_output(val, virtual= True)
            self._opened = True
            self.portNameChanged.emit()
            self.openedChanged.emit()

    @Slot(int, int, int)
    def note_off(self, channel, note, velocity):
        if self.outport is not None and not self.outport.closed:
            print("Note off, Channel: "+str(channel))
            msg = mido.Message('note_off', channel=channel, note=note, velocity=velocity)
            self.outport.send(msg)

    @Slot(int, int, int)
    def note_on(self, channel, note, velocity):
        if self.outport is not None and not self.outport.closed:
            print("Note on, Channel: "+str(channel)+ ", Note: "+str(note))
            msg = mido.Message('note_on', channel=channel, note=note, velocity=velocity)
            self.outport.send(msg)

    @Slot(int, int, int)
    def polytouch(self, channel, note, value):
        if self.outport is not None and not self.outport.closed:
            msg = mido.Message('polytouch', channel=channel, note=note, value=value)
            self.outport.send(msg)

    @Slot(int, int, int)
    def control_change(self, channel, control, value):
        if self.outport is not None and not self.outport.closed:
            msg = mido.Message('control_change', channel=channel, control=control, value=value)
            self.outport.send(msg)

    @Slot(int, int)
    def program_change(self, channel, program):
        if self.outport is not None and not self.outport.closed:
            msg = mido.Message('program_change', channel=channel, program=program)
            self.outport.send(msg)

    @Slot(int, int)
    def aftertouch(self, channel, value):
        if self.outport is not None and not self.outport.closed:
            msg = mido.Message('aftertouch', channel=channel, value=value)
            self.outport.send(msg)

    @Slot(int, float)
    def pitchwheel(self, channel, pitch):
        if self.outport is not None and not self.outport.closed:
            pitchWheel = int(128/ 24 * pitch) + 64
            msg = mido.Message('pitchwheel', channel=channel, pitch=pitchWheel)
            # print("Pitch bend, Channel: "+str(channel)+ ", Note: "+str(pitch))
            self.outport.send(msg)

    @Slot(int)
    def sysex(self, data):
        if self.outport is None and not self.outport.closed:
            msg = mido.Message('sysex', data=data)
            self.outport.send(msg)
