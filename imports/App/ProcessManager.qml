pragma Singleton
import QtQuick 2.12

import hcmusic.plot 1.0
import hcmusic.dsp 1.0
import hcmusic.loader 1.0

QtObject {
    property CsvLoader csv: CsvLoader {}

    property PhaseWireCalc c2cConv: PhaseWireCalc {
        input: csv.output
        onCalcFinished: {
            channelUnits = csv.getChannelVUnits()
            let info = {
                "date": csv.getChannelDate(0),
                "time": csv.getChannelTime(0)
            }
            trn.setBaseInfo(info)
        }
    }

    property ThermalReportNode trn: ThermalReportNode {
        input: c2cConv.output
        type: "BDEW"
    }

    property ValueAxis sectionAxis: ValueAxis {
        min: 1000
        max: c2cConv.output.length
        property bool edited: false

        onMinChanged: {
            if(min <=  0) min = 0
            // app.setT1(min)
            reportDelay.restart()
        }
        onMaxChanged: {
            if(max >= c2cConv.output.length) max = c2cConv.output.length
            // app.setT2(max)
            reportDelay.restart()
        }

        function updateReport() {
            if (gatherModel.count < 1) return 
            DisplaySetting.cursor = [
                {"name": "No.", "v1": min.toFixed(0), "v2": max.toFixed(0), "v3": max.toFixed(0) - min.toFixed(0)}
            ]
            DisplaySetting.previewData = c2cConv.getReport(min.toFixed(0), max.toFixed(0))
        }
    }

    property Timer reportDelay: Timer{
        interval: 100
        onTriggered: sectionAxis.updateReport()
    }

    property ListModel gatherModel: ListModel {}
}