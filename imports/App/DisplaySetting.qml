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
            "I+", "I-", "I0", "U-sig", "I-sig", "P-sig", "Q-sig", "S+", "S-",
            "CH1", "CH2", "CH3", "CH4", "CH5", "CH6",
            "CH12", "CH23", "CH13", "CH45", "ch56", "CH46"
        ]
        property var channel: {
            "P+": [0],
            "Q+": [1],
            "P-": [2],
            "Q-": [3],
            "P0": [4],
            "Q0": [5],
            "U+": [6],
            "U-": [7],
            "U0": [8],
            "IP+": [9], 
            "IQ+": [10],
            "IP-": [11], 
            "IQ-": [12], 
            "IP0": [13], 
            "IQ0": [14],
            "pf+": [15], 
            "pf-": [16], 
            "pf0": [17],

            "U1": [18],
            "U2": [19],
            "U3": [20],
            "I1": [21],
            "I2": [22],
            "I3": [23],
            "P1": [24], 
            "P2": [25], 
            "P3": [26], 
            "Q1": [27], 
            "Q2": [28], 
            "Q3": [29],
            "I+": [30], 
            "I-": [31], 
            "I0": [32], 
            "U-sig": [33], 
            "I-sig": [34], 
            "P-sig": [35], 
            "Q-sig": [36], 
            "S+": [37], 
            "S-": [38],
            "CH1": [39], 
            "CH2": [40], 
            "CH3": [41], 
            "CH4": [42], 
            "CH5": [43], 
            "CH6": [44],
            "CH12": [39, 40], 
            "CH23": [40, 41], 
            "CH13": [39, 41],
            "CH45": [42, 43], 
            "CH56": [43, 44], 
            "CH46": [42, 44],
        }
        onChannelNamesChanged: {
            clear()
            for(let i = 0; i< channelNames.length; i++) {
                append({"name": channelNames[i], "value": false})
            }
        }

        function getSelectedChannel() {
            let ret = []
            for(let i = 0; i< channelModel.count; i++) {
                if(channelModel.get(i)["value"]) {
                    ret.push(channel[channelModel.get(i)["name"]])
                    // console.log(channel[channelModel.get(i)["name"]])
                    // console.log(typeof channel[channelModel.get(i)["name"]])
                }
            }
            return ret
        }
    }

    property variant cursor
    property variant previewData
}