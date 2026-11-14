/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import "media.js" as Media

// The volume level indicator (media-controls-09; M3 LevelIndicator, tag
// PlayerScreenVolumeIndicator, MS/hj.java:530-650, MS/gsc.java:140-153): a
// 72 deg arc, 6 dp stroke (12 px), secondaryDim over surfaceContainer, on the
// left edge (the crown is on the right), filling from the bottom. It fades in
// at every volume change and out 2500 ms after the last one; on the Volume
// screen it stays (`alwaysShown`). Hidden, it draws nothing and no timer runs.
Item {
    id: root

    /*! 0..1 */
    property real level: 0
    property bool alwaysShown: false
    property int holdMs: Media.LEVEL_HOLD_MS
    readonly property real stroke: Theme.dp(Media.LEVEL_STROKE)
    readonly property real arcRadius: width / 2 - Theme.size.scrollIndicatorEdgeGap - stroke / 2
    readonly property real startAngle: 180 - Media.LEVEL_SWEEP / 2
    readonly property bool shown: alwaysShown || _on
    readonly property alias trackArc: track
    readonly property alias fillArc: fill
    property bool _on: false

    function show() {
        _on = true
        hide.restart()
    }

    visible: opacity > 0
    opacity: shown ? 1 : 0
    Behavior on opacity {
        NumberAnimation { duration: Motion.springDuration(Motion.standard.defaultEffects.stiffness) }
    }

    Timer {
        id: hide
        interval: root.holdMs
        repeat: false
        onTriggered: root._on = false
    }

    ProgressArc {
        id: track
        anchors.fill: parent
        radius: root.arcRadius
        strokeWidth: root.stroke
        color: Theme.color.surfaceContainer
        startAngle: root.startAngle
        sweepAngle: Media.LEVEL_SWEEP
    }

    ProgressArc {
        id: fill
        anchors.fill: parent
        radius: root.arcRadius
        strokeWidth: root.stroke
        color: Theme.color.secondaryDim
        startAngle: root.startAngle
        sweepAngle: Media.LEVEL_SWEEP * Media.clamp01(root.level)
    }
}
