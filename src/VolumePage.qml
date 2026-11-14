/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import "media.js" as Media

// The Volume screen (media-controls-07; Horologist M3 VolumeScreen,
// MS/hj.java:300-453, MS/grt.java:175-183): a stepper with the volume-up
// button at the top and volume-down at the bottom (60 x 48 dp, primaryContainer
// with a primary icon; disabled 16 % / 38 %), the output device chip in the
// middle (device name and Connected / Not Connected, primaryContainer, 18 dp
// side padding) or, without a device, the label "Volume" (labelMedium); the
// level arc always shown; the crown changes the volume as on the player. A
// swipe back (the LayerStack) returns to the player.
Item {
    id: root

    /*! 0..1 */
    property real volume: 0
    /*! The phone's step count is not sent over our link: 5 % steps. */
    property int maxSteps: 20
    property string deviceName: ""
    property bool connected: true
    /*! The user asked for this level. */
    signal volumeRequested(real level)

    readonly property real u: Theme.dp(1)
    readonly property alias arc: level
    readonly property alias crown: crown
    readonly property alias increase: up
    readonly property alias decrease: down

    function change(v) {
        var next = Media.clamp01(v)
        if (Math.abs(next - volume) < 1e-6) {
            try {
                if (typeof Haptics.gestureEnd === "function")
                    Haptics.gestureEnd()
            } catch (e) { }
        } else {
            try {
                if (typeof Haptics.segmentTick === "function")
                    Haptics.segmentTick()
            } catch (e) { }
            volumeRequested(next)
        }
        level.show()
    }

    //% "Volume"
    readonly property string volumeText: qsTrId("id-media-volume")
    //% "Increase Volume"
    readonly property string increaseText: qsTrId("id-media-volume-up")
    //% "Decrease Volume"
    readonly property string decreaseText: qsTrId("id-media-volume-down")
    //% "Volume muted"
    readonly property string mutedText: qsTrId("id-media-volume-muted")
    //% "Volume set to %1%"
    readonly property string percentText: qsTrId("id-media-volume-percent")
    //% "Connected"
    readonly property string connectedText: qsTrId("id-media-connected")
    //% "Not Connected"
    readonly property string notConnectedText: qsTrId("id-media-not-connected")

    // the live region text
    readonly property string levelText: volume <= 0 ? mutedText : percentText.arg(Math.round(volume * 100))

    Accessible.role: Accessible.Slider
    Accessible.name: volumeText
    Accessible.description: levelText

    LevelArc {
        id: level
        anchors.fill: parent
        level: root.volume
        alwaysShown: true
    }

    component StepButton: MouseArea {
        id: sb
        property string iconName
        property string name
        property bool atLimit: false
        width: Theme.dp(60)
        height: Theme.dp(48)
        anchors.horizontalCenter: parent.horizontalCenter
        Accessible.role: Accessible.Button
        Accessible.name: name
        Rectangle {
            id: box
            anchors.fill: parent
            color: sb.atLimit ? Qt.rgba(Theme.color.onSurface.r, Theme.color.onSurface.g, Theme.color.onSurface.b, 0.16)
                              : Theme.color.primaryContainer
            radius: height / 2 + (Theme.shape.small - height / 2) * morph.value
            clip: true
            WearSpring {
                id: morph
                to: sb.pressed ? 1 : 0
                stiffness: sb.pressed ? Motion.pressMorph.press.stiffness : Motion.pressMorph.release.stiffness
                dampingRatio: 1.0
            }
            Ripple { radius: box.radius; color: Theme.color.primary; pressed: sb.pressed; pressX: sb.mouseX; pressY: sb.mouseY }
        }
        Icon {
            anchors.centerIn: parent
            width: Theme.size.iconSmall
            height: width
            name: sb.iconName
            color: sb.atLimit ? Qt.rgba(Theme.color.onSurface.r, Theme.color.onSurface.g, Theme.color.onSurface.b, Theme.alpha.disabledContent)
                              : Theme.color.primary
        }
    }

    StepButton {
        id: up
        iconName: "ms-volume_up"
        name: root.increaseText
        atLimit: root.volume >= 1
        anchors.top: parent.top
        anchors.topMargin: Theme.margin.scaffoldVertical
        onClicked: root.change(root.volume + 1 / root.maxSteps)
    }

    StepButton {
        id: down
        iconName: "ms-volume_down"
        name: root.decreaseText
        atLimit: root.volume <= 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.margin.scaffoldVertical
        onClicked: root.change(root.volume - 1 / root.maxSteps)
    }

    Item {
        id: middle
        anchors {
            top: up.bottom
            bottom: down.top
            left: parent.left
            right: parent.right
            topMargin: Theme.space.m
            bottomMargin: Theme.space.m
        }

        // the output device chip
        Rectangle {
            id: chip
            visible: root.deviceName !== ""
            anchors.centerIn: parent
            height: Math.min(parent.height, Theme.dp(40))
            width: Math.min(Theme.dp(150), Math.max(nameLabel.contentWidth, stateLabel.contentWidth) + 2 * Theme.dp(18))
            radius: height / 2
            color: Theme.color.primaryContainer
            Column {
                anchors.centerIn: parent
                Label {
                    id: nameLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    role: "labelMedium"
                    text: root.deviceName
                    color: Theme.color.onPrimaryContainer
                    elide: Text.ElideRight
                    width: Math.min(contentWidth, chip.width - 2 * Theme.dp(18))
                }
                Label {
                    id: stateLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    role: "labelSmall"
                    text: root.connected ? root.connectedText : root.notConnectedText
                    color: Theme.color.onSurfaceVariant
                    elide: Text.ElideRight
                    width: Math.min(contentWidth, chip.width - 2 * Theme.dp(18))
                }
            }
        }

        // or the label "Volume"
        Label {
            id: volumeLabel
            visible: root.deviceName === ""
            anchors.centerIn: parent
            role: "labelMedium"
            text: root.volumeText
            color: Theme.color.onSurface
        }
    }

    CrownVolume {
        id: crown
        anchors.fill: parent
        volume: root.volume
        maxSteps: root.maxSteps
        onStepped: function (next, steps) {
            root.volumeRequested(next)
            level.show()
        }
    }
}
