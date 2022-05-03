import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    id: root

    property real value
    property real from: -100000
    property real to: 100000
    property real stepSize: 0.01

    property real decimals: 2


    SpinBox {
        id: spinBox
        width: root.width
        height: root.height
        stepSize: root.stepSize * Math.pow(10, root.decimals)
        from: root.from * Math.pow(10, root.decimals)
        to: root.to * Math.pow(10, root.decimals)
        value: root.value * Math.pow(10, root.decimals)

        validator: DoubleValidator {
            bottom: Math.min(spinBox.from, spinBox.to)
            top: Math.max(spinBox.from, spinBox.to)
        }

        textFromValue: function(value, locale) {
            return Number(value / Math.pow(10, root.decimals)).toLocaleString(locale, 'f', root.decimals)
        }

        valueFromText: function(text, locale) {
            return Number.fromLocaleString(locale, text) * Math.pow(10, root.decimals)
        }

        onValueChanged: {
            if(root.value != this.value / Math.pow(10, root.decimals))
                root.value = this.value / Math.pow(10, root.decimals)
        }
        editable: true
    }
}