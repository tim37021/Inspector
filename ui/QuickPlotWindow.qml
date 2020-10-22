import QtQuick 2.12
import App 1.0
import hcmusic.plot 1.0
import Algo 1.0

SubWindow {

    property var signalSource       ///< raw jsarray or buffered signal source
    property SubWindow plotWindow
    property SubWindow stftWindow

    onSignalSourceChanged: {
        let arr=getArray()
        ls.set(arr)
        fit(arr)
    }

    Timer {
        running: true
        interval: 100
        repeat: true

        onTriggered: {
            let arr;
            if(signalSource && signalSource.array)
                arr = signalSource.array
            if(signalSource && Array.isArray(signalSource))
                arr = signalSource
            
            // move mouse cursor
            if(plot.mouseCoordX >= 0 && plot.mouseCoordX < arr.length) {
                // nearest mode
                plot.mouseAnchor.px = Math.round(plot.mouseCoordX)
                plot.mouseAnchor.py = arr[plot.mouseAnchor.px]
                
                
                // interpolate mode
                // plot.mouseAnchor.px = plot.mouseCoordX
                // let t = plot.mouseCoordX - Math.floor(plot.mouseCoordX);
                // plot.mouseAnchor.py = (1-t)*arr[Math.floor(plot.mouseCoordX)]+t*arr[Math.ceil(plot.mouseCoordX)]
                
            }
            
        }
    }
   

    Connections {
        target: signalSource instanceof QtObject? signalSource: null

        function onUpdate(array) {
            ls.set(array)
        }
    }

    Rectangle {
        y: 24
        width: plot.width + 16
        height: plot.height + 16
        anchors.centerIn: parent
        color: "transparent"

        radius: 8

        border.color: "white"
        border.width: 1
    }

    InteractivePlot {
        id: plot
        y: 24
        width: parent.width * 0.9
        height: parent.height * 0.8
        anchors.centerIn: parent
        gridSizeX: ls.length / 20
        gridSizeY: 500000


        xAxis: ValueAxis {
            id: xAxis_
            min: 0
            max: 4096
        }

        yAxis: ValueAxis {
            id: yAxis_
            min: -1000000
            max: 1000000
        }

        LineSeries {
            id: ls
            xAxis: xAxis_
            yAxis: yAxis_
            color: Qt.rgba(247/255, 193/255, 121/255, 1.0)
            length: 1
            lineWidth: 2
        }

        function argMin(array) {
            return array.map((x, i) => [x, i]).reduce((r, a) => (a[0] < r[0] ? a : r))[1];
        }

        onSelectChanged: {
            let startX = Math.floor(Math.min(recAnchor.x1, recAnchor.x2))
            let endX = Math.floor(Math.max(recAnchor.x1, recAnchor.x2))
            let min = Math.min(...getArray().slice(startX, endX))
            let max = Math.max(...getArray().slice(startX, endX))

            recAnchor.y1 = min
            recAnchor.y2 = max
        }

        Keys.onPressed: {
            // key binding....
            if(event.key == 65) {
                let arr = getArray()
                if(plot.mouseCoordX >= 0 && plot.mouseCoordX < arr.length) {
                    let startX = Math.floor(plot.mouseCoordX)
                    let x = algo.autocorrelation(getArray().slice(startX, startX+1024).buffer, 32, 500, 256)
                    x = new Array(32).fill(0).concat(x)
                    let min = argMin(x.slice(32))+32
                    app.notify(32000/min)
                    if(plotWindow==null)
                        plotWindow = app.createQuickPlotWindow('autocorrelation', x)
                    else {
                        plotWindow.signalSource = x
                    }
                }
                
            }

            if(event.key == 66) {
                let arr = getArray()
                if(plot.mouseCoordX >= 0 && plot.mouseCoordX < arr.length) {
                    let startX = Math.floor(plot.mouseCoordX)
                    let x = algo.stft(getArray().slice(startX, startX+4096).buffer, 32000, 1024, 512)
                    if(stftWindow==null)
                        stftWindow = app.createImageWindow('stft', x)
                    else {
                        stftWindow.signalSource = x
                    }
                }
                
            }

            if(event.key == 67) {
                let arr = getArray()
                if(plot.mouseCoordX >= 0 && plot.mouseCoordX < arr.length) {
                    let startX = Math.floor(plot.mouseCoordX)
                    let x = algo.fft(getArray().slice(startX, startX+1024).buffer)
                    if(plotWindow==null)
                        plotWindow = app.createQuickPlotWindow('fft', x)
                    else {
                        plotWindow.signalSource = x
                    }
                }
                
            }

            if(event.key == 68) {
                let arr = getArray()
                if(plot.mouseCoordX >= 0 && plot.mouseCoordX < arr.length) {
                    let startX = Math.floor(plot.mouseCoordX)
                    let x = algo.hybridMethod(getArray().slice(startX, startX+1024).buffer)
                    app.notify(x)
                }
                
            }
            if(event.key == 69) {
                let arr = getArray().slice(0)
                let x = algo.launch(arr.buffer)
                plot.rectangleModel.clear()
                for(let i=0; i<x.rectangles.length; i++) {
                    plot.rectangleModel.append(x.rectangles[i])
                }
                
            }
        }
    }

    ListView {
        id: lv
        anchors.bottom: parent.bottom
        anchors.left: plot.left
        
        width: plot.width
        height: parent.height * 0.1
        orientation: ListView.Horizontal

        // If siganlSource has channels
        model: signalSource.channels? signalSource.channels: 0

        delegate: Item {
            width: 128
            height: lv.height
            clip: true

            Row {
                spacing: 10
                anchors.fill: parent
                Rectangle {
                    radius: 8
                    width: 16
                    height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: {
                        
                        if(lv.currentIndex === index)
                            return "green"
                        else
                            return "gray"
                    }
                }
                Text {
                    text: `Channel ${modelData}`
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: lv.currentIndex = index
            } 

        }

        onCurrentIndexChanged: {
            signalSource.channel = lv.currentIndex
        }
    }

    function fit(arr) {
        plot.xAxis.min = 0
        plot.xAxis.max = arr.length

        plot.yAxis.min = Math.min(...arr)
        plot.yAxis.max = Math.max(...arr)

        plot.gridSizeY = (plot.yAxis.max - plot.yAxis.min) / 20
    }

    AlgorithmPool {
        id: algo
    }

    function getArray() {
        let arr;
        if(signalSource && signalSource.array)
            arr = signalSource.array
        if(signalSource && Array.isArray(signalSource))
            // TODO: allow using Float32Array for signalSource for low overhead calc
            arr = new Float32Array(signalSource)
        return arr
    }
}