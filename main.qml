import QtQuick 2.12
import QtQuick.Controls 2.12
import nrf.beacon 1.0
import App 1.0

ApplicationWindow {
    id: app
    width: Constants.width
    height: Constants.height
    visible: true
    color: Constants.background

    property DeviceManager deviceMgr: DeviceManager {

    }

    SideBar {
        id: sb
        color: Constants.foreground1
        content: ListView {
            model: app.deviceMgr.enumModel
            spacing: 16

            anchors.fill: parent
            delegate: DeviceButton {
                id: deviceBtn
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.8
                height: 48
                scanner: app.deviceMgr.getScanner(display)
                port: display

                property SubWindow window

                Connections {
                    target: app.deviceMgr.getScanner(display)
                    function onStateChanged(v) {
                        if(target.state == BeaconScanner.Scanning && deviceBtn.window == null) {
                            deviceBtn.window = app.createPlotWindow(display, scanner.model)
                        }

                    }
                }

            }
        }
        
    }

    ///> Windowing system for this app
    Windowing {
        id: windowing
    }

    Component {
        id: plotWindowComp
        PlotWindow {
            width: app.width * 0.8
            height: app.height * 0.8
        }
    }

    Component {
        id: quickPlotWindowComp
        QuickPlotWindow {
            width: app.width * 0.8
            height: app.height * 0.8
        }
    }

    /**
     * createPlotWindow
     * @param title Title of the new window
     * @param mdl Instance of TrackedDeviceModel
     */
    function createPlotWindow(title, mdl) {
        return windowing.createWindow(plotWindowComp, {open: true, title: title, target: mdl});
    }

    /**
     * createQuickPlotWindow
     * @param title Title of the new window
     * @param source Signal source. Can be raw array
     */
    function createQuickPlotWindow(title, source) {
        return windowing.createWindow(quickPlotWindowComp, {open: true, title: title, signalSource: source});
    }

    function moveToTop(window) {
        windowing.moveToTop(window)
    }
}

