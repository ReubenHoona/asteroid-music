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

Application {
    id: app

    centerColor: "#2577B3"
    outerColor: "#000619"

    property bool isPlaying: mprisController.currentService && mprisController.playbackStatus == Mpris.Playing
    property double bufferedVolume: 0.0

    onBufferedVolumeChanged: mprisController.volume = bufferedVolume

    // Where the track is (the phone tells asteroid-btsyncd at play, pause and
    // seek): run on here while it plays, refreshed once a second while shown
    property double basePosition: 0
    property double baseTime: 0
    property double shownPosition: 0
    readonly property double duration: mprisController.metaData.duration ? mprisController.metaData.duration : 0
    // The phone's player, when the phone said which (asteroid-btsyncd's own
    // name otherwise)
    readonly property string playerName: mprisController.identity && mprisController.identity !== "Asteroid BLE Sync Daemon"
                                         ? mprisController.identity : ""

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

    onIsPlayingChanged: syncPosition()
    Component.onCompleted: syncPosition()

    Timer {
        interval: 1000
        repeat: true
        running: app.isPlaying && app.duration > 0 && Qt.application.state === Qt.ApplicationActive
        onTriggered: app.updatePosition()
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

    StatusPage {
        //% "<h3>No data</h3>Sync AsteroidOS with your phone."
        text: qsTrId("id-no-data-sync")
        icon: "ios-sync"
        visible: !btStatus.connected
    }

    Item {
        anchors.fill: parent
        visible: btStatus.connected

        // The crown changes the phone's volume, a step per notch
        WheelHandler {
            enabled: btStatus.connected
            onWheel: function (event) {
                if (event.angleDelta.y === 0)
                    return
                var step = event.angleDelta.y > 0 ? 0.05 : -0.05
                bufferedVolume = Math.max(0, Math.min(1, bufferedVolume + step))
            }
        }

        Label {
            id: playerLabel
            anchors.bottom: songLabel.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: Dims.w(40)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.pixelSize: Dims.l(4)
            opacity: 0.7
            visible: app.playerName !== ""
            text: app.playerName
        }

        Image {
            id: coverArt
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            opacity: 0.7
            source: mprisController.metaData.artUrl ? mprisController.metaData.artUrl : ""
        }

        Rectangle {
            id: textBackgroundDarkener
            visible: coverArt.status == Image.Ready
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: artistLabel.bottom
            anchors.bottomMargin: -Dims.h(0.5)
            color: "black"
            opacity: 0.5
        }

        Marquee {
            id: songLabel
            font.bold: true
            anchors.top: parent.top
            anchors.topMargin: Dims.h(7)
            anchors.horizontalCenter: parent.horizontalCenter
            height: Dims.h(10)
            width: DeviceSpecs.hasRoundScreen ? Dims.w(60) : Dims.w(80)

            text: mprisController.metaData.title ? mprisController.metaData.title : ""
        }

        Marquee {
            id: artistLabel
            anchors.top: songLabel.bottom
            anchors.topMargin: -Dims.h(1)
            anchors.horizontalCenter: parent.horizontalCenter
            height: Dims.h(10)
            width: DeviceSpecs.hasRoundScreen ? Dims.w(70) : Dims.w(80)

            text: (mprisController.metaData.contributingArtist || []).join(", ")
        }

        // How far the track is
        Rectangle {
            id: progressTrack
            visible: app.duration > 0
            anchors.top: artistLabel.bottom
            anchors.topMargin: Dims.h(1)
            anchors.horizontalCenter: parent.horizontalCenter
            width: Dims.w(44)
            height: Dims.h(1)
            radius: height / 2
            color: "white"
            opacity: 0.3
        }

        Rectangle {
            visible: progressTrack.visible
            anchors.left: progressTrack.left
            anchors.verticalCenter: progressTrack.verticalCenter
            height: progressTrack.height
            radius: height / 2
            width: progressTrack.width * Math.max(0, Math.min(1, app.shownPosition / Math.max(1, app.duration)))
            color: "white"
        }

        IconButton {
            id: previousButton
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: Dims.iconButtonMargin
            }
            iconName: "ios-arrow-dropleft"
            onClicked: if (mprisController.canGoPrevious) mprisController.previous()
        }

        IconButton {
            id: playButton
            anchors.centerIn: parent
            width: Dims.w(40)
            height: width
            iconName: isPlaying ? "ios-pause" : "ios-play"
            onClicked: {
                if (isPlaying && mprisController.canPause)
                    mprisController.pause()
                else if (!isPlaying && mprisController.canPlay)
                    mprisController.play()
            }
        }

        IconButton {
            id: nextButton
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: Dims.iconButtonMargin
            }
            iconName: "ios-arrow-dropright"
            onClicked: if (mprisController.canGoNext) mprisController.next()
        }

        IconButton {
            id: volDownButton
            anchors.left: parent.left
            anchors.leftMargin: Dims.w(16)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Dims.h(12)
            iconName: "ios-volume-down"
            onClicked: bufferedVolume = Math.max(bufferedVolume - 0.05, 0)
        }

        Rectangle {
            id: volumeSlider
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Dims.h(21)
            anchors.horizontalCenter: parent.horizontalCenter
            height: Dims.h(2)
            width: Dims.w(28)
            color: "white"
            opacity: 0.6
            radius: 12
        }

        Rectangle {
            anchors.top: volumeSlider.top
            anchors.left: volumeSlider.left
            anchors.bottom: volumeSlider.bottom
            width: volumeSlider.width * mprisController.volume
            color: "white"
            radius: 12
            opacity: 1.0
        }

        IconButton {
            id: volUpButton
            anchors.right: parent.right
            anchors.rightMargin: Dims.w(16)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Dims.h(12)
            iconName: "ios-volume-up"
            onClicked: bufferedVolume = Math.min(bufferedVolume + 0.05, 1)
        }
    }
}
