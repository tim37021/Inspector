import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    property string parameter: "Parameter"
    property var types
    property string key
    property var itemRange: ""

    signal accepted
    signal cleared
    signal editingFinished

    id: root
    Loader {
        id: loader
        sourceComponent: {
            for(let i=0 ; i < 3; i++){
                switch(root.types[i]) {
                    case "text":
                        return textInputComponent
                    case "bool":
                        return boolInputComponent
                    case "enum":
                        return enumInputComponent
                    case "int":
                        return intInputComponent
                    case "float":
                        return floatInputComponent
                }
            }
        }

        
    }

    Component.onCompleted: {

        loader.item.load(parameter, types, itemRange)
    }

    Component {
        id: textInputComponent
        TextInputBox {
            width: root.width
            height: root.height

            onAccepted: root.accepted()
            onEditingFinished: root.editingFinished()
            onClear: root.clear()
            onTextChanged: root.parameter = text

            function load(value, type, range) {
                this.text = value
            }
        }
    }

    Component {
        id: boolInputComponent
        BoolInputBox {
            width: root.width
            height: root.height

            onValueChanged: {
                if(this.value)
                    root.parameter = "True"
                else
                    root.parameter = "False"

                root.editingFinished()
            }

            function load(value, type, range) {
                if(value == "True")
                    this.value = true
                else
                    this.value = false
            }
        }
    }

    Component {
        id: enumInputComponent
        EnumInputBox {
            width: root.width
            height: root.height

            onValueChanged: {
                root.parameter = this.value
                root.editingFinished()
            }

            function load(value, type, range) {
                if(typeof range !== "undefined"){
                    this.enumItems = range
                }
                this.value = value
                this.onLoaded()
            }
        }
    }

    Component {
        id: intInputComponent
        IntInputBox {
            width: root.width
            height: root.height

            onValueChanged: {
                root.parameter = this.value
                root.editingFinished()
            }

            function load(value, type, range) {
                this.value = parseInt(value)

                if(typeof range !== "undefined") {
                    let ranges = range[0].split("~")

                    if(ranges[0] !== "")
                        this.from = parseInt(ranges[0])
                    else{
                        this.from = -10000000
                    }
                    if(ranges[1] !== "")
                        this.to = parseInt(ranges[1])
                    else{
                        this.to = 10000000
                    }
                }
                
            }
        }
    }

    Component {
        id: floatInputComponent
        FloatInputBox {
            width: root.width
            height: root.height

            onRealValueChanged: {
                root.parameter = this.realValue
                root.editingFinished()
            }

            function load(value, type, range) {
                this.value = value * this.mod
                
                if(typeof range !== "undefined") {
                    let ranges = range[0].split("~")

                    if(ranges[0] !== "")
                        this.from = ranges[0]* this.mod
                    else {
                        this.from = -10000000
                    }
                    if(ranges[1] !== "")
                        this.to = ranges[1]* this.mod
                    else{
                        this.to = 10000000
                    }
                }
                
            }
        }
    }
}