import QtQuick 2.12
import QtQuick.Controls 2.12

Item {
    id: root
    property var enumItems
    property string value

    ComboBox {
        id: combo
        width: root.width
        height: root.height
        currentIndex: {
            return find(root.value)
        }
        model: ListModel { id: model}

        onCurrentTextChanged: {
            root.value = currentText
        }
    }

    function onLoaded () {
        for(let i =0; i< 30; i++) {
            if(typeof root.enumItems[i]  === 'undefined') 
                break
            
            model.append({text: root.enumItems[i]})
        }
        combo.currentIndex = combo.find(root.value)
    }
}