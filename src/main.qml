/*
 * Copyright (C) 2016 - Florent Revest <revestflo@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import Amber.Mpris
import "media.js" as Media

// Media Controls: the phone's player over MPRIS (asteroid-btsyncd). The screens
// are PlayerPage (layout, buttons, crown) and VolumePage; this file keeps the
// MPRIS state and the track position. Black background, no mesh, the curved
// time on top (media-controls-01, -13).
Application {
    id: app

    // stock's app scaffold shows the curved time (media-controls-13); it follows
    // the 12 / 24 hour setting
    showTime: true
    // the Wear OS 6 Media Controls has its time 1 dp from the edge (digit top
    // y 10, S33)
    timeTextMargin: Theme.dp(1)

    // Is the phone linked (btsyncd's state)? The tests set it.
    property bool linkUp: btStatus.connected
    // Display on and app in front: the turning button, the marquee and the
    // position timer all stop otherwise
    property bool interactive: Qt.application.state === Qt.ApplicationActive

    readonly property bool hasService: !!mprisController.currentService
    readonly property bool isPlaying: hasService && mprisController.playbackStatus == Mpris.Playing
    readonly property string statusName: !hasService ? "stopped"
        : mprisController.playbackStatus == Mpris.Playing ? "playing"
        : mprisController.playbackStatus == Mpris.Paused ? "paused" : "stopped"
    property double bufferedVolume: 0.0

    onBufferedVolumeChanged: mprisController.volume = bufferedVolume

    // The phone's artwork and its colours (media-controls-11): the picture behind the player (ArtBackground)
    // and a colour scheme seeded from its dominant colour (MS/gts.java:9-50, a tonal-spot scheme of that
    // colour); every screen of the app takes it (the player, the queue: MS/fl.java:5631, 6246), as the
    // badge, the play shape and the pills do. Without a colour: the system's colours (MS/gqe.java:90).
    // What btsyncd says is taken over at once while the app is in front with the screen on, else when it
    // comes back: nothing is worked out or redrawn for a screen that is off.
    property string shownArtPath: ""
    property string shownArtColor: ""
    readonly property string artSource: shownArtPath !== "" ? "file://" + shownArtPath : ""
    /*! The roles are the artwork's (not the system's). */
    property bool artThemed: false

    function takeArt() {
        shownArtPath = mediaLink.artPath
        shownArtColor = mediaLink.artColor
    }

    function applyArtScheme() {
        var seed = Media.artSeed(shownArtColor)
        if (seed !== "") {
            var g = PaletteGenerator.generate(seed, "", Media.ART_SCHEME_STYLE)
            if (g && g.primary !== undefined) {
                Theme._setRoles(g)
                artThemed = true
                return
            }
        }
        if (artThemed) {
            artThemed = false
            Theme.applyColorTheme(true)
        }
    }

    onShownArtColorChanged: applyArtScheme()
    onInteractiveChanged: if (interactive) takeArt()

    MediaLink {
        id: mediaLink
        live: app.interactive
        onArtUpdated: if (app.interactive) app.takeArt()
    }

    // the system's colour theme changed (Settings): the artwork's colours stay
    Connections {
        target: Theme
        function on_ColorThemeChanged() {
            if (app.artThemed)
                Qt.callLater(app.applyArtScheme)
        }
    }

    // Where the track is (the phone tells asteroid-btsyncd at play, pause and
    // seek): run on here while it plays, refreshed once a second while shown
    property double basePosition: 0
    property double baseTime: 0
    property double shownPosition: 0
    readonly property double duration: mprisController.metaData.duration ? mprisController.metaData.duration : 0

    // "Loading…" for the first 2 s while the phone's player is not known yet
    // (media-controls-14); one single shot, no polling
    property bool waitedOut: false
    readonly property alias refreshTimer: positionTimer
    // for the tests
    readonly property alias mpris: mprisController
    readonly property alias link: mediaLink

    readonly property var shown: Media.describe({
        linkUp: linkUp,
        hasService: hasService,
        status: statusName,
        title: mprisController.metaData.title ? mprisController.metaData.title : "",
        artist: (mprisController.metaData.contributingArtist || []).join(", "),
        waitedOut: waitedOut
    })

    //% "Playing"
    readonly property string unknownTitle: qsTrId("id-media-unknown-title")
    //% "No title or details"
    readonly property string unknownDetails: qsTrId("id-media-unknown-details")
    //% "Phone"
    readonly property string phoneText: qsTrId("id-media-phone")

    // the player app's name on the phone ("" not told): the header of More Actions and the queue
    readonly property string playerApp: Media.playerName(mprisController.identity)

    readonly property string titleText: shown.kind !== "media" ? "" : shown.unknown ? unknownTitle : shown.title
    readonly property string artistText: shown.kind !== "media" ? "" : shown.unknown ? unknownDetails : shown.artist
    readonly property real progress: shown.kind === "media" && duration > 0
        ? Math.max(0, Math.min(1, shownPosition / duration)) : -1

    function syncPosition() {
        basePosition = Math.max(0, mprisController.position)
        baseTime = Date.now()
        updatePosition()
    }

    function updatePosition() {
        var p = basePosition
        if (isPlaying)
            p += (Date.now() - baseTime) * (mprisController.rate > 0 ? mprisController.rate : 1)
        shownPosition = duration > 0 ? Math.min(p, duration) : p
    }

    // The crown or the Volume screen asked for this level
    function setVolume(level) {
        bufferedVolume = Math.max(0, Math.min(1, level))
    }

    function togglePlay() {
        if (isPlaying && mprisController.canPause)
            mprisController.pause()
        else if (!isPlaying && mprisController.canPlay)
            mprisController.play()
    }

    onIsPlayingChanged: syncPosition()
    Component.onCompleted: syncPosition()

    // The play button's outlines that the first frame does not show (the scallop of a playing track, the
    // pills of a press: Media.shapeRadii, about 120 rays each) are worked out after it, one after each
    // frame the window shows (its frameSwapped), before they are wanted; one wanted sooner is worked out
    // then.
    readonly property var laterShapes: ["scallop", "wide", "narrow"]
    property int shapesMade: 0
    Connections {
        target: app.Window.window
        enabled: app.shapesMade < app.laterShapes.length
        function onFrameSwapped() { Qt.callLater(app.makeNextShape) }
    }
    function makeNextShape() {
        if (shapesMade >= laterShapes.length)
            return
        Media.shapeRadii(laterShapes[shapesMade])
        shapesMade++
    }

    Timer {
        id: positionTimer
        interval: 1000
        repeat: true
        running: app.isPlaying && app.duration > 0 && app.interactive
        onTriggered: app.updatePosition()
    }

    Timer {
        interval: Media.LOADING_MS
        repeat: false
        running: !app.waitedOut
        onTriggered: app.waitedOut = true
    }

    MprisController {
        id: mprisController
        onVolumeChanged: bufferedVolumeTimer.restart()
        onPositionChanged: app.syncPosition()
    }

    BluetoothStatus { id: btStatus }

    Timer {
        id: bufferedVolumeTimer
        interval: 500
        repeat: false
        onTriggered: bufferedVolume = mprisController.volume
    }

    Component {
        id: playerComponent
        Item {
            // the phone's artwork (media-controls-11)
            ArtBackground {
                objectName: "artBackground"
                anchors.fill: parent
                source: app.artSource
                animate: app.interactive
            }

            PlayerPage {
                id: player
                objectName: "player"
                anchors.fill: parent
                kind: app.shown.kind
                title: app.titleText
                artist: app.artistText
                playing: app.isPlaying
                canPrevious: mprisController.canGoPrevious
                canNext: mprisController.canGoNext
                canPlayPause: app.isPlaying ? mprisController.canPause : mprisController.canPlay
                volume: app.bufferedVolume
                progress: app.progress
                active: app.interactive
                onPlayPause: app.togglePlay()
                onPrevious: if (mprisController.canGoPrevious) mprisController.previous()
                onNext: if (mprisController.canGoNext) mprisController.next()
                onOutputClicked: layerStack.push(volumeComponent)
                onVolumeRequested: function (level) { app.setVolume(level) }
                // More Actions: the player's custom actions and Up Next (media-controls-19, -20)
                hasMore: mediaLink.hasMore && app.shown.kind === "media"
                onMoreClicked: layerStack.push(moreComponent)
            }
        }
    }

    Component {
        id: volumeComponent
        VolumePage {
            objectName: "volumePage"
            volume: app.bufferedVolume
            deviceName: app.phoneText
            connected: app.linkUp
            onVolumeRequested: function (level) { app.setVolume(level) }
        }
    }

    Component {
        id: moreComponent
        MorePage {
            objectName: "morePage"
            appName: app.playerApp
            actions: mediaLink.actions
            upNext: mediaLink.upNext
            onActionClicked: function (index) { mediaLink.customAction(index) }
            onQueueClicked: layerStack.push(queueComponent)
        }
    }

    Component {
        id: queueComponent
        QueuePage {
            objectName: "queuePage"
            appName: app.playerApp
            queue: mediaLink.queue
            current: mediaLink.current
            playing: app.isPlaying
            active: app.interactive
            onItemClicked: function (index) {
                mediaLink.playQueueItem(index)
                app.backToPlayer()
            }
        }
    }

    // a queue item was chosen: back to the player (stock navigates to player?page=0, MS/hg.java ad())
    function backToPlayer() {
        while (layerStack.layers.length > 1)
            layerStack.pop(layerStack.currentLayer)
        layerStack.popAnim()
    }

    LayerStack {
        id: layerStack
        objectName: "layerStack"
        firstPage: playerComponent
        win: app
    }
}
