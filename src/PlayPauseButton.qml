/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Shapes
import org.asteroid.controls
import "media.js" as Media

// The Media Controls play / pause button (media-controls-03, -05; Horologist
// M3 AnimatedPlayPauseButton, MS/fl.java:4470-4925).
//
// A 64 dp slot with a 64 dp shape (the Wear OS 6 look, S33; CP3A 60 dp) in
// the primary colour: a 10 point rounded scallop (outer 32 dp, inner 25.6 dp,
// corners 12 dp) turning anticlockwise by
// 36 deg per 3 s (linear, restarting) while playing, a circle while paused,
// morphing between them. A button of the group being pressed morphs it toward
// a pill 12 dp wider (itself) or narrower (a neighbour). The glyph morphs
// between two bars and a triangle in 170 ms. The track progress is a 4 dp ring
// on the outline (turning with the shape), the filled shape shrinks to 51.2 dp
// while it shows; loading shows an indeterminate circular indicator instead.
// The turning runs only while playing, shown and `active`.
Item {
    id: root

    property bool playing: false
    property bool loading: false
    /*! Played fraction 0..1, negative when unknown (no ring). */
    property real progress: -1
    /*! dp the group asks the shape to grow (+) or shrink (-), at most 12. */
    property real squeeze: 0
    /*! The display is on and the app in front: nothing turns otherwise. */
    property bool active: true
    readonly property alias pressed: area.pressed
    signal clicked()

    readonly property real u: Theme.dp(1)
    readonly property bool ringShown: progress >= 0 && !loading
    readonly property bool marked: ringShown || loading

    // 0 circle .. 1 scallop, 0 pause glyph .. 1 play glyph
    property real morph: playing ? 1 : 0
    property real glyphT: playing ? 0 : 1
    property real fillScale: marked ? Media.RING_INNER / (2 * Media.SCALLOP_OUTER) : 1

    Behavior on morph { NumberAnimation { duration: 300 * Motion.animationScale; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.easing.standard } }
    Behavior on glyphT { NumberAnimation { duration: Media.ICON_MORPH_MS * Motion.animationScale; easing.type: Easing.Linear } }
    Behavior on fillScale { NumberAnimation { duration: 250 * Motion.animationScale; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.easing.standard } }

    readonly property var _scallop: Media.radii(Media.scallopPolygon(), Media.RING_SAMPLES)
    readonly property var _circle: Media.circleRadii(Media.SCALLOP_OUTER, Media.RING_SAMPLES)
    readonly property var _wide: Media.radii(Media.pillPolygon(2 * Media.SCALLOP_OUTER + Media.EXPAND, 2 * Media.SCALLOP_OUTER), Media.RING_SAMPLES)
    readonly property var _narrow: Media.radii(Media.pillPolygon(2 * Media.SCALLOP_OUTER - Media.EXPAND, 2 * Media.SCALLOP_OUTER), Media.RING_SAMPLES)
    readonly property real squeezeAmount: Math.max(-1, Math.min(1, squeeze / Media.EXPAND))
    // the outline now, in dp
    readonly property var radiiNow: {
        var base = Media.blend(_circle, _scallop, morph)
        if (squeezeAmount === 0)
            return base
        return Media.blend(base, squeezeAmount > 0 ? _wide : _narrow, Math.abs(squeezeAmount))
    }

    readonly property real half: width / 2
    function placed(pts) {
        var o = []
        for (var i = 0; i < pts.length; i++)
            o.push(Qt.point(pts[i].x + half, pts[i].y + half))
        return o
    }
    readonly property var fillPoints: placed(Media.outline(radiiNow, u * fillScale, 0))
    readonly property var ring: ringShown
        ? Media.ringPaths(radiiNow, u, Media.RING_STROKE / 2, progress, u * Media.RING_GAP, u * Media.RING_STROKE)
        : { played: [], rest: [], length: 0 }

    readonly property color fillColor: enabled ? Theme.color.primary
        : Qt.rgba(Theme.color.onSurface.r, Theme.color.onSurface.g, Theme.color.onSurface.b, 0.16)
    readonly property color glyphColor: enabled ? Theme.color.onPrimary
        : Qt.rgba(Theme.color.onSurface.r, Theme.color.onSurface.g, Theme.color.onSurface.b, Theme.alpha.disabledContent)

    // for the tests: is the shape turning
    readonly property bool turning: spinAnim.running
    readonly property real turn: spin.rotation

    implicitWidth: u * Media.PLAY_SLOT
    implicitHeight: implicitWidth

    Accessible.role: Accessible.Button
    //% "Play"
    readonly property string playText: qsTrId("id-media-play")
    //% "Pause"
    readonly property string pauseText: qsTrId("id-media-pause")
    Accessible.name: playing ? pauseText : playText

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.enabled
        onClicked: root.clicked()
    }

    Item {
        id: spin
        anchors.fill: parent

        Shape {
            id: fillShape
            anchors.fill: parent
            ShapePath {
                strokeWidth: -1
                fillColor: root.fillColor
                PathPolyline { path: root.fillPoints }
            }
        }

        Shape {
            anchors.fill: parent
            visible: root.ringShown
            ShapePath {
                strokeWidth: root.u * Media.RING_STROKE
                strokeColor: Theme.color.surfaceContainerLow
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: root.placed(root.ring.rest) }
            }
            ShapePath {
                strokeWidth: root.u * Media.RING_STROKE
                strokeColor: Theme.color.onSecondaryContainer
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: root.placed(root.ring.played) }
            }
        }
    }

    NumberAnimation {
        id: spinAnim
        target: spin
        property: "rotation"
        from: 0
        to: Media.ROTATE_DEG
        duration: Media.ROTATE_MS
        loops: Animation.Infinite
        running: root.playing && root.active && root.visible
    }

    CircularProgressIndicator {
        anchors.centerIn: parent
        width: root.u * 2 * Media.SCALLOP_OUTER
        height: width
        visible: root.loading
        indeterminate: true
        strokeWidth: root.u * Media.RING_STROKE
        color: Theme.color.onSecondaryContainer
        trackColor: Theme.color.surfaceContainerLow
        displayOn: root.active
    }

    Shape {
        anchors.fill: parent
        ShapePath {
            strokeWidth: -1
            fillColor: root.glyphColor
            PathPolyline { path: root.placed(Media.glyphA(root.glyphT, root.u)) }
        }
        ShapePath {
            strokeWidth: -1
            fillColor: root.glyphColor
            PathPolyline { path: root.placed(Media.glyphB(root.glyphT, root.u)) }
        }
    }
}
