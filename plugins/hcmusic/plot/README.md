hcmusic.plot Module
======
This modules aims to provide simple and efficient implementation plot functionalities for QML.

## Modules
There are three main components in this module.

- SignalPlotOpenGL - optimized for signal plot. The APIs is very similar to QtCharts modules. It used OpenGL 2.1/3.3 for rendering.
- SignalPlotUI - provides handy plot functionalities for drawing stuff/UIs in signal space
- SignalPlotControl - provides UX logic like mouse control to axises and keyboard responses, etc.

If you are using QtCharts and this module in the same component, please assign one of them a namespace.

```qml
import hcmusic.plot 1.0 as hcplot
```

## Examples
Here we provide some basic usage of this module.

### Example 1
The basic usage is similar to QtCharts except that LineSeries is an array of y values.
```qml
SignalPlotOpenGL {
    anchors.fill: parent
    clearColor: "black"
    ValueAxis {
        id: xAxis_
        min: 0
        max: 256
    }

    ValueAxis {
        id: yAxis_
        min: -1
        max: 1
    }

    LineSeries {
        xAxis: xAxis_
        yAxis: yAxis_

        color: "red"

        length: 256
    }
}
```

### Example 2
Adding controls by simply provides xAxis_ and yAxis_ to SignalPlotControl object
```qml
SignalPlotOpenGL {
    anchors.fill: parent
    clearColor: "black"
    ValueAxis {
        id: xAxis_
        min: 0
        max: 256
    }

    ValueAxis {
        id: yAxis_
        min: -1
        max: 1
    }

    //...
    SignalPlotControl {
        xAxis: xAxis_
        yAxis: yAxis_

        // Important!!
        anchors.fill: parent
    }
}
```

### Example 3
```qml
SignalPlotUI {
    xAxis: xAxis_
    yAxis: yAxis_
    
}
```

## TODO
- Configurable keybinding
- Renaming and reorganizing
- Support more primitives for drawing