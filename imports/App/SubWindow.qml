
/****************************************************************************
**
** Copyright (C) 2019 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the examples of the Qt Design Studio.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.8
import QtQuick.Timeline 1.0
import QtQuick.Controls 2.3

Rectangle {
    id: root
    width: 937
    height: 582
    property bool open: false

    property bool __internalOpen: state == "Open"
    property bool __internalClosed: state == "Closed"

    color: Qt.rgba(0.1434, 0.1758, 0.2405)
    opacity: ma.drag.active? 0.5196: 0.7

    Behavior on opacity {
        NumberAnimation { duration: 100 }
    }

    radius: 20

    property string title

    Text {
        x: 8
        y: 8
        text: title
        color: Qt.rgba(63/255, 169/255, 245/255, 1)
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        drag.target: parent
        onPressed: {
            parent.focus = true
            app.moveToTop(root)
        }
    }


    Item {
        width: 16
        height: 16
        x: parent.width-width
        y: parent.height-height

        onXChanged: parent.width = x+width
        onYChanged: parent.height = y+height

        MouseArea {
            drag.target: parent
            anchors.fill: parent
        }

    }



    Timeline {
        id: timeline
        animations: [
            TimelineAnimation {
                id: closing
                onFinished: root.state = "Closed"
                from: 1000
                running: false
                to: 0
                loops: 1
                duration: 1000
            },
            TimelineAnimation {
                id: opening
                onFinished: root.state = "Open"
                from: 0
                running: false
                to: 1000
                loops: 1
                duration: 1000
            }
        ]
        endFrame: 1000
        enabled: true
        startFrame: 0

        KeyframeGroup {
            target: root
            property: "scale"
            Keyframe {
                easing.bezierCurve: [0.175, 0.885, 0.32, 1.27, 1, 1]
                value: 1
                frame: 603
            }

            Keyframe {
                value: "0"
                frame: 0
            }
        }
    }

    states: [

        State {
            name: "open"

            PropertyChanges {
                target: timeline
                currentFrame: 1000
                enabled: true
            }
        },

        State {
            when: root.open && !root.__internalOpen
            name: "Opening"

            PropertyChanges {
                target: timeline
                enabled: true
            }

            PropertyChanges {
                target: opening
                running: true
            }
        },

        State {
            name: "closed"

            PropertyChanges {
                target: timeline
                currentFrame: 0
                enabled: true
            }
        },

        State {
            when: !root.open && !root.__internalClosed
            name: "Closing"

            PropertyChanges {
                target: timeline
                enabled: true
            }

            PropertyChanges {
                target: closing
                running: true
            }
        }
    ]
}
