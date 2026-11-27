/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import "media.js" as Media

// The mark of the queue item that plays (media-controls-20; MS/fl.java o(), MS/duh.java:45-56): while it
// plays, stock's equaliser_animated_icon, three round-ended bars rising and falling in a 2 s loop (the
// drawable's keyframes, Media.EQ_KEYS); paused, the static paused_equaliser (three short bars on the
// baseline) described as "Paused" (current_song_paused). 16 dp, in the content colour. The loop runs only
// while it is shown with the screen on (\l active): no frame is drawn otherwise.
Item {
    id: root

    property bool playing: false
    /*! The display is on and the app in front. */
    property bool active: true
    property color color: Theme.color.onSurface

    readonly property real u: Theme.dp(1)
    readonly property bool animating: loop.running
    /*! ms into the loop */
    property real phase: 0
    readonly property var tops: Media.equaliserTops(phase)

    //% "Paused"
    readonly property string pausedText: qsTrId("id-media-paused")

    width: u * Media.EQ_SIZE
    height: width

    Accessible.role: Accessible.Graphic
    Accessible.name: playing ? "" : pausedText

    NumberAnimation on phase {
        id: loop
        from: 0
        to: Media.EQ_LOOP_MS
        duration: Media.EQ_LOOP_MS
        loops: Animation.Infinite
        running: root.playing && root.active && root.visible
    }

    Repeater {
        model: 3
        Rectangle {
            required property int index
            readonly property real barTop: root.playing ? root.tops[index] : Media.EQ_PAUSED_Y
            x: root.u * (root.playing ? Media.EQ_BAR_X[index] - Media.EQ_BAR_W / 2 : Media.EQ_PAUSED_X[index])
            width: root.u * (root.playing ? Media.EQ_BAR_W : Media.EQ_PAUSED_W)
            y: root.u * barTop
            height: root.u * (root.playing ? Media.EQ_BOTTOM - barTop : Media.EQ_PAUSED_H)
            radius: Math.min(width, height) / 2
            color: root.color
            antialiasing: true
        }
    }
}
