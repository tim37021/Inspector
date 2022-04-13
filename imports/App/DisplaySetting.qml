pragma Singleton
import QtQuick 2.12

QtObject {
    property ListModel channelModel: ListModel {
        id: channelModel
        property var channelNames: [
            "P+", "Q+", "P-", "Q-", "P0", "Q0",
            "U+", "U-", "U0",
            "IP+", "IQ+", "IP-", "IQ-", "IP0", "IQ0",
            "pf+", "pf-", "pf0",
            "U1", "U2", "U3", "I1", "I2", "I3",
            "P1", "P2", "P3", "Q1", "Q2", "Q3",
            "I+", "I-", "I0", "U-sig", "I-sig", "P-sig", "Q-sig"
        ]
        onChannelNamesChanged: {
            clear()
            for(let i = 0; i< channelNames.length; i++) {
                append({"name": channelNames[i], "value": false})
                console.log(channelNames[i])
            }
        }

        function getSelectedChannel() {
            let ret = []
            for(let i = 0; i< channelModel.count; i++) {
                if(channelModel.get(i)["value"]) {
                    ret.push(i)
                }
            }
            return ret
        }
    }
}