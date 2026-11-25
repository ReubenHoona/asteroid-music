/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import "media.js" as Media

// The Media Controls player (Horologist M3 PlayerScreen on the Pixel Watch 2,
// media-controls-01..06, -08, -09, -14): a Column of three boxes filling the
// 192 dp screen, space between: the top box 64 dp (24 dp padding on top for the
// curved time, 2 dp below) holding the 38 dp media display (title row 128 x 20
// dp, artist row 144 x 18 dp) aligned to its bottom, the middle box 64 dp with
// the button group (previous pill, play / pause shape, next pill), the bottom
// box 64 dp with the output row. The Wear OS 6 look (S33) centres the button
// group on the screen (CP3A: top box 68 dp, bottom box 60 dp). On black, no
// mesh.
//
// This item only draws what it is given; main.qml owns the MPRIS state.
Item {
    id: root

    /*! "loading", "nothing" (nothing playing, or the phone is gone) or "media" */
    property string kind: "media"
    property string title
    property string artist
    property bool playing: false
    property bool canPrevious: true
    property bool canNext: true
    property bool canPlayPause: true
    /*! 0..1 */
    property real volume: 0
    /*! Played fraction, negative when the length is unknown. */
    property real progress: -1
    /*! The display is on and the app in front: nothing animates otherwise. */
    property bool active: true
    property bool hasMore: false

    signal playPause()
    signal previous()
    signal next()
    signal outputClicked()
    signal moreClicked()
    /*! The crown asked for this volume (0..1). */
    signal volumeRequested(real level)

    readonly property real u: Theme.dp(1)
    readonly property bool isMedia: kind === "media"
    readonly property alias levelArc: level
    readonly property alias crown: crown
    readonly property alias playButton: play
    readonly property alias previousButton: prev
    readonly property alias nextButton: nextPill
    readonly property alias outputRow: bottom
    readonly property alias titleRow: titleRow
    readonly property alias artistRow: artistRow
    readonly property alias statusLabel: status
    readonly property alias groupSpring: expand
    readonly property var slotWidths: Media.groupWidths([Media.PILL_W, Media.PLAY_SLOT, Media.PILL_W], _idx, expand.value)

    //% "Nothing playing"
    readonly property string nothingText: qsTrId("id-media-nothing-playing")
    //% "Loading…"
    readonly property string loadingText: qsTrId("id-media-loading")
    //% "Previous"
    readonly property string previousText: qsTrId("id-media-previous")
    //% "Next"
    readonly property string nextText: qsTrId("id-media-next")

    // ---- top box: the media display ----
    readonly property real displayTop: u * (Media.TOP_H - Media.TOP_PAD_BOTTOM - Media.DISPLAY_H)

    SwapText {
        id: titleRow
        x: (root.width - width) / 2
        y: root.displayTop
        width: root.u * Media.TITLE_W
        height: root.u * Media.TITLE_H
        visible: root.isMedia
        text: root.title
        marquee: true
        role: "titleMedium"
        inDelay: Media.TITLE_IN
        outDelay: Media.TITLE_OUT
        paused: !root.active
    }

    SwapText {
        id: artistRow
        x: (root.width - width) / 2
        y: root.displayTop + root.u * Media.TITLE_H
        width: root.u * Media.ARTIST_W
        height: root.u * Media.ARTIST_H
        visible: root.isMedia
        text: root.artist
        role: "bodyMedium"
        inDelay: Media.ARTIST_IN
        outDelay: Media.ARTIST_OUT
        paused: true
    }

    // Nothing playing / Loading…: titleMedium onSurfaceVariant, centred in the
    // 38 dp display box, 75 % wide
    Label {
        id: status
        x: (root.width - width) / 2
        y: root.displayTop
        width: root.u * Media.ARTIST_W
        height: root.u * Media.DISPLAY_H
        visible: !root.isMedia
        role: "titleMedium"
        color: Theme.color.onSurfaceVariant
        text: root.kind === "loading" ? root.loadingText : root.nothingText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        maximumLineCount: 1
    }

    // ---- middle box: the button group ----
    readonly property int pressedIndex: prev.pressed ? 0 : play.pressed ? 1 : nextPill.pressed ? 2 : -1
    property int _idx: -1
    onPressedIndexChanged: if (pressedIndex >= 0) _idx = pressedIndex

    WearSpring {
        id: expand
        to: root.pressedIndex >= 0 ? 1 : 0
        stiffness: root.pressedIndex >= 0 ? Motion.pressMorph.press.stiffness : Motion.pressMorph.release.stiffness
        dampingRatio: 1.0
    }

    readonly property real midTop: u * Media.TOP_H
    readonly property real groupX: u * Media.GROUP_SIDE
    readonly property real gap: u * Media.PILL_GAP

    SkipButton {
        id: prev
        direction: -1
        name: root.previousText
        enabled: root.isMedia && root.canPrevious
        x: root.groupX
        y: root.midTop + root.u * (Media.MID_H - Media.PILL_H) / 2
        width: root.u * root.slotWidths[0]
        height: root.u * Media.PILL_H
        onClicked: root.previous()
    }

    PlayPauseButton {
        id: play
        enabled: root.isMedia && root.canPlayPause
        playing: root.playing && root.isMedia
        loading: root.kind === "loading"
        progress: root.isMedia ? root.progress : -1
        squeeze: root.slotWidths[1] - Media.PLAY_SLOT
        active: root.active
        width: root.u * Media.PLAY_SLOT
        height: width
        x: root.groupX + root.u * root.slotWidths[0] + root.gap + (root.u * root.slotWidths[1] - width) / 2
        y: root.midTop + (root.u * Media.MID_H - height) / 2
        onClicked: root.playPause()
    }

    SkipButton {
        id: nextPill
        direction: 1
        name: root.nextText
        enabled: root.isMedia && root.canNext
        width: root.u * root.slotWidths[2]
        height: root.u * Media.PILL_H
        x: root.width - root.groupX - width
        y: prev.y
        onClicked: root.next()
    }

    // ---- bottom box: the output row ----
    OutputRow {
        id: bottom
        x: 0
        y: root.u * (Media.TOP_H + Media.MID_H)
        width: root.width
        height: root.u * Media.BOTTOM_H
        hasOutput: root.isMedia
        hasMore: root.hasMore
        volume: root.volume
        onOutputClicked: root.outputClicked()
        onMoreClicked: root.moreClicked()
    }

    LevelArc {
        id: level
        anchors.fill: parent
        level: root.volume
        z: 5
    }

    CrownVolume {
        id: crown
        anchors.fill: parent
        volume: root.volume
        onStepped: function (next, steps) {
            root.volumeRequested(next)
            level.show()
        }
    }
}
