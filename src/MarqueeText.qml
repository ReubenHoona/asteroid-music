/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import "media.js" as Media

// Horologist MarqueeText (media-controls-02, MS/fl.java:936-1157): text that
// fits is centred and still. Text that does not fit starts after 4 s, runs
// left at 64 dp/s with a second copy 96 dp behind the first, wraps, pauses 4 s
// per cycle (a loop, not back and forth), with 8 dp edge fades while it moves.
// Nothing runs while `paused` or hidden.
Item {
    id: root

    property string text
    property string role: "titleMedium"
    property color color: Theme.color.onSurface
    /*! No animation: the display is off, the app is not in front, or hidden. */
    property bool paused: false
    property int startDelay: Media.MARQUEE_PAUSE
    property real speed: Theme.dp(Media.MARQUEE_SPEED)
    property real gapWidth: Theme.dp(Media.MARQUEE_GAP)
    property real fadeWidth: Theme.dp(Media.MARQUEE_FADE)

    readonly property real textWidth: first.contentWidth
    readonly property bool overflows: width > 0 && textWidth > width
    readonly property real distance: textWidth + gapWidth
    readonly property bool active: overflows && !paused && visible
    readonly property bool scrolling: anim.running && offset > 0
    property real offset: 0

    clip: true
    implicitHeight: first.height

    onActiveChanged: restart()
    onTextChanged: restart()
    onDistanceChanged: restart()
    onSpeedChanged: restart()

    function restart() {
        anim.stop()
        offset = 0
        if (active && distance > 0)
            anim.start()
    }

    Label {
        id: first
        role: root.role
        text: root.text
        color: root.color
        width: contentWidth
        elide: Text.ElideNone
        wrapMode: Text.NoWrap
        x: root.overflows ? -root.offset : (root.width - contentWidth) / 2
        y: Math.round((root.height - height) / 2)
    }

    Label {
        role: root.role
        text: root.text
        color: root.color
        width: contentWidth
        elide: Text.ElideNone
        wrapMode: Text.NoWrap
        visible: root.overflows
        x: first.x + first.contentWidth + root.gapWidth
        y: first.y
    }

    SequentialAnimation {
        id: anim
        loops: Animation.Infinite
        PauseAnimation { duration: root.startDelay }
        NumberAnimation {
            target: root
            property: "offset"
            from: 0
            to: root.distance
            duration: root.speed > 0 ? Math.round(1000 * root.distance / root.speed) : 0
            easing.type: Easing.Linear
        }
    }

    // 8 dp edge fades, only while the text moves
    Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: root.fadeWidth
        visible: root.scrolling
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.color.background }
            GradientStop { position: 1; color: "transparent" }
        }
    }
    Rectangle {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: root.fadeWidth
        visible: root.scrolling
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 1; color: Theme.color.background }
        }
    }
}
