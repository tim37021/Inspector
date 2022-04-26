pragma Singleton
import QtQuick 2.12

QtObject {
    property ListModel channelModel: ListModel {
        id: channelModel
        property string type: "PW3P3W"
        property var channelNames: {
            if(type.includes("PW3P3W"))
                return [
                    "P+", "Q+", "P-", "Q-", "P0", "Q0",
                    "U+", "U-", "U0",
                    "IP+", "IQ+", "IP-", "IQ-", "IP0", "IQ0",
                    "pf+", "pf-", "pf0",
                    "U1", "U2", "U3", "I1", "I2", "I3",
                    "P1", "P2", "P3", "Q1", "Q2", "Q3",
                    "I+", "I-", "I0", "U-sig", "I-sig", "P-sig", "Q-sig", "S+", "S-",
                    "CH1", "CH2", "CH3", "CH4", "CH5", "CH6",
                    "CH12", "CH23", "CH31", "CH45", "CH56", "CH64", "IP1", "IP2", "IP3", "IQ1", "IQ2", "IQ3",
                ]
            else 
                return [
                    "P+", "Q+", "P-", "Q-", "P0", "Q0",
                    "U+", "U-", "U0",
                    "IP+", "IQ+", "IP-", "IQ-", "IP0", "IQ0",
                    "pf+", "pf-", "pf0",
                    "U1-N", "U2-N", "U3-N", "I1", "I2", "I3",
                    "P1", "P2", "P3", "Q1", "Q2", "Q3",
                    "I+", "I-", "I0", "U-sig", "I-sig", "P-sig", "Q-sig", "S+", "S-",
                    "CH1", "CH2", "CH3", "CH4", "CH5", "CH6",
                    "CH12", "CH23", "CH31", "CH45", "CH56", "CH64", 
                    "L1-L2", "L2-L3", "L3-L1", "IP1", "IP2", "IP3", "IQ1", "IQ2", "IQ3",
                ]
        }
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
            "CH12": [45], 
            "CH23": [46], 
            "CH31": [47],
            "CH45": [48], 
            "CH56": [49], 
            "CH64": [50],
            "L1-L2": [57],
            "L2-L3": [58],
            "L3-L1": [59],
            "U1-N": [18],
            "U2-N": [19],
            "U3-N": [20],
            "IP1": [51],
            "IP2": [52],
            "IP3": [53],
            "IQ1": [53],
            "IQ2": [55],
            "IQ3": [56],
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