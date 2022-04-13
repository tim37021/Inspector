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
            // trn.calc()
        }
    }

    property ThermalReportNode trn: ThermalReportNode {
        input: c2cConv.output
        type: "BDEW"
    }
}