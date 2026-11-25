/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Shapes
import org.asteroid.controls
import "media.js" as Media

// The bottom row of Media Controls (media-controls-06, -14; MS/gye.java:67-342,
// 4179-4880): two equal cells padded 28 dp left and right, 16 dp from the top
// (pill y 288, the Wear OS 6 look, S33; CP3A 3 dp),
// a 44 x 32 dp pill in each (onSurface 24 %, disabled 16 %), icons 24 dp.
// Left: the output device (a smartphone: the phone plays) with an 18 dp badge,
// a 7 point soft star in primaryDim shifted 9 dp past the top end corner, with
// a 14 dp onPrimary volume icon chosen by the level (mute at the minimum, up
// at the maximum, down between); a tap opens the Volume screen. Right: More
// Actions (three dots), shown only when the player has more actions; without
// them the output pill is the only one and is centred, as stock does.
// Nothing playing: the pill shows the output-off icon (a struck phone and
// speaker, ms-media_output_off, S33) and is disabled.
Item {
    id: root

    property bool hasOutput: true
    property bool hasMore: false
    property real volume: 0
    signal outputClicked()
    signal moreClicked()

    readonly property real u: Theme.dp(1)
    readonly property alias outputPill: left
    readonly property alias morePill: right
    readonly property string badgeIcon: Media.volumeIcon(volume)
    readonly property real cellWidth: (width - 2 * u * Media.BOTTOM_SIDE) / 2

    function _alpha(a) {
        return Qt.rgba(Theme.color.onSurface.r, Theme.color.onSurface.g, Theme.color.onSurface.b, a)
    }

    //% "Set Volume"
    readonly property string setVolumeText: qsTrId("id-media-set-volume")
    //% "Choose device"
    readonly property string chooseDeviceText: qsTrId("id-media-choose-device")
    //% "More Actions"
    readonly property string moreText: qsTrId("id-media-more-actions")

    component Pill: MouseArea {
        id: pill
        default property alias content: holder.data
        property string name
        width: root.u * Media.OUT_PILL_W
        height: root.u * Media.OUT_PILL_H
        y: root.u * Media.BOTTOM_TOP
        Accessible.role: Accessible.Button
        Accessible.name: name
        Rectangle {
            id: box
            anchors.fill: parent
            radius: height / 2
            color: root._alpha(pill.enabled ? 0.24 : 0.16)
            clip: true
            Ripple {
                radius: box.radius
                color: Theme.color.onSurface
                pressed: pill.enabled && pill.pressed
                pressX: pill.mouseX
                pressY: pill.mouseY
            }
        }
        Item { id: holder; anchors.fill: parent }
    }

    Pill {
        id: left
        enabled: root.hasOutput
        name: root.hasOutput ? root.setVolumeText : root.chooseDeviceText
        x: root.hasMore ? root.u * Media.BOTTOM_SIDE + (root.cellWidth - width) / 2 : (root.width - width) / 2
        onClicked: root.outputClicked()

        Icon {
            anchors.centerIn: parent
            width: root.u * Media.OUT_ICON
            height: width
            name: root.hasOutput ? "ms-smartphone" : "ms-media_output_off"
            color: root._alpha(root.hasOutput ? 1 : Theme.alpha.disabledContent)
        }

        Item {
            id: badge
            visible: root.hasOutput
            width: root.u * Media.BADGE
            height: width
            x: left.width - width + root.u * Media.BADGE_SHIFT
            y: 0
            readonly property var points: {
                var poly = Media.roundedPolygon(Media.starVertices(7, Media.BADGE / 2, Media.BADGE / 2 * 0.86), 3)
                var o = []
                for (var i = 0; i < poly.length; i++)
                    o.push(Qt.point(root.u * poly[i][0] + width / 2, root.u * poly[i][1] + height / 2))
                return o
            }
            Shape {
                anchors.fill: parent
                ShapePath {
                    strokeWidth: -1
                    fillColor: Theme.color.primaryDim
                    PathPolyline { path: badge.points }
                }
            }
            Icon {
                anchors.centerIn: parent
                width: root.u * Media.BADGE_ICON
                height: width
                name: root.badgeIcon
                color: Theme.color.onPrimary
            }
        }
    }

    Pill {
        id: right
        visible: root.hasMore
        name: root.moreText
        x: root.u * Media.BOTTOM_SIDE + root.cellWidth + (root.cellWidth - width) / 2
        onClicked: root.moreClicked()

        // three dots (an original glyph: the Material one is not in the icon set)
        Column {
            anchors.centerIn: parent
            spacing: root.u * 3
            Repeater {
                model: 3
                Rectangle {
                    width: root.u * 4
                    height: width
                    radius: width / 2
                    color: Theme.color.onSurface
                }
            }
        }
    }
}
