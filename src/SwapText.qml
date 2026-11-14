/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import "media.js" as Media

// One row of the media display with stock's track change (media-controls-02,
// MS/fl.java:3017-3020, 2190): the old text slides out to -12.5 % of the row
// width with a fade, the new one slides in from +12.5 % with a fade, 300 ms
// FastOutSlowIn, each after its own delay. The title row scrolls when too wide
// (MarqueeText), the artist row is one line with an ellipsis.
Item {
    id: root

    property string text
    property bool marquee: false
    property string role: "bodyMedium"
    property color color: Theme.color.onSurface
    property int inDelay: 0
    property int outDelay: 0
    property bool paused: false
    readonly property real shift: width * Media.SWAP_SHIFT
    readonly property int duration: Math.round(Media.SWAP_MS * Motion.animationScale)

    // the slot that shows the text now
    readonly property Item current: _useA ? slotA : slotB
    readonly property Item leaving: _useA ? slotB : slotA
    property bool _useA: true
    property bool _ready: false

    clip: false

    Component.onCompleted: {
        slotA.text = text
        slotA.opacity = 1
        _ready = true
    }

    onTextChanged: {
        if (!_ready)
            return
        if (current.text === text)
            return
        var incoming = leaving
        var outgoing = current
        _useA = !_useA
        incoming.text = text
        incoming.go(0, shift, 0, inDelay, 0, 1, true)
        outgoing.go(outgoing.dx, 0, 1, outDelay, -shift, 0, false)
    }

    component Slot: Item {
        id: slot
        property string text
        property real dx: 0
        width: root.width
        height: root.height
        x: dx
        opacity: 0

        function go(from, start, startOpacity, delay, to, toOpacity, entering) {
            seq.stop()
            if (entering) {
                dx = start
                opacity = startOpacity
            }
            pause.duration = delay
            moveX.to = entering ? 0 : to
            moveOp.to = toOpacity
            seq.start()
        }

        SequentialAnimation {
            id: seq
            PauseAnimation { id: pause }
            ParallelAnimation {
                NumberAnimation {
                    id: moveX
                    target: slot
                    property: "dx"
                    duration: root.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.easing.legacy
                }
                NumberAnimation {
                    id: moveOp
                    target: slot
                    property: "opacity"
                    duration: root.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.easing.legacy
                }
            }
        }

        MarqueeText {
            anchors.fill: parent
            visible: root.marquee
            text: slot.text
            role: root.role
            color: root.color
            paused: root.paused || slot.opacity <= 0
        }

        Label {
            anchors.fill: parent
            visible: !root.marquee
            text: slot.text
            role: root.role
            color: root.color
            elide: Text.ElideRight
            maximumLineCount: 1
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    Slot { id: slotA }
    Slot { id: slotB }
}
