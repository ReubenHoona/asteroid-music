/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import "media.js" as Media

// The previous / next pill of the Media Controls button group
// (media-controls-04, MS/fl.java:2691-2805, 4004-4180): primaryDim fill, a
// 32 dp skip arrow in onPrimary, outlined (Material Symbols FILL 0) as in the
// Wear OS 6 look (S33; CP3A filled), a short skip animation on tap (500 ms: the
// arrow runs ahead and comes back). Disabled: onSurface 16 %, icon 38 %.
// `direction` is -1 for previous, +1 for next.
Item {
    id: root

    property int direction: 1
    property string iconName: direction < 0 ? "ms-skip_previous" : "ms-skip_next"
    property string name
    readonly property alias pressed: area.pressed
    signal clicked()

    readonly property real u: Theme.dp(1)
    readonly property real iconDx: icon.x - (width - icon.width) / 2

    Accessible.role: Accessible.Button
    Accessible.name: name

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: Math.min(width, height) / 2
        color: root.enabled ? Theme.color.primaryDim
            : Qt.rgba(Theme.color.onSurface.r, Theme.color.onSurface.g, Theme.color.onSurface.b, 0.16)
        clip: true

        Ripple {
            radius: pill.radius
            color: Theme.color.onPrimary
            pressed: root.enabled && area.pressed
            pressX: area.mouseX
            pressY: area.mouseY
        }

        Icon {
            id: icon
            name: root.iconName
            width: root.u * Media.SKIP_ICON
            height: width
            y: (parent.height - height) / 2
            x: (parent.width - width) / 2
            color: root.enabled ? Theme.color.onPrimary
                : Qt.rgba(Theme.color.onSurface.r, Theme.color.onSurface.g, Theme.color.onSurface.b, Theme.alpha.disabledContent)
        }
    }

    // 500 ms in all: ahead 250 ms, back 250 ms
    SequentialAnimation {
        id: skip
        NumberAnimation {
            target: icon; property: "x"
            to: (pill.width - icon.width) / 2 + root.direction * root.u * 6
            duration: 250 * Motion.animationScale
            easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.easing.legacy
        }
        NumberAnimation {
            target: icon; property: "x"
            to: (pill.width - icon.width) / 2
            duration: 250 * Motion.animationScale
            easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.easing.legacy
        }
    }
    readonly property alias skipping: skip.running

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.enabled
        onClicked: {
            skip.restart()
            root.clicked()
        }
    }
}
