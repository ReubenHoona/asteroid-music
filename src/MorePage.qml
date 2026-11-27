/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import "media.js" as Media

// More Actions (media-controls-19; route players/{sessionId}/overflow): stock's Material 3 list
// (MS/fl.java:3240-3300) has three items, here in a ScalingList with stock's padding (MS/grt.java:68-76):
// - "header": the player app (MS/grz.java:10-20: 28 % of the width tall, its name); the phone tells its
//   name (btsyncd's MPRIS identity), else the screen's name, "More Actions";
// - "overflow_actions": the player's custom actions as a button group of the first three (MS/fl.java A(),
//   MS/hg.java af()/ag(): min(size, 3), 52 dp, 8 dp apart, surfaceContainer). The phone cannot send the
//   player's icons (app resources), so a known name gets its symbol (Media.actionIcon) and any other shows
//   its name; the name is the button's accessible name. A tap runs the action on the phone (media command 5);
// - "queue_button": the Up Next card (MS/fl.java y(): an app card with the queue icon, "Up Next" and the
//   next item's title, disabled without one, MS/a.java V()), which opens the queue.
// The per-app auto-launch entry of stock has no counterpart (no media auto-launch here).
Item {
    id: root

    /*! The player app's name ("" when the phone did not say). */
    property string appName: ""
    /*! The custom actions' names, in the phone's order. */
    property var actions: []
    /*! The next item's title ("" none known). */
    property string upNext: ""

    // set by the LayerStack that shows the page
    property int depth: 0
    property var pop: null

    signal actionClicked(int index)
    signal queueClicked()

    readonly property real u: Theme.dp(1)
    readonly property var shownActions: (actions || []).slice(0, Media.MAX_ACTIONS_SHOWN)
    readonly property var rows: shownActions.length > 0 ? ["header", "actions", "queue"] : ["header", "queue"]
    readonly property alias list: list

    //% "More Actions"
    readonly property string moreText: qsTrId("id-media-more-actions")
    //% "Up Next"
    readonly property string upNextText: qsTrId("id-media-up-next")
    //% "Media Queue"
    readonly property string queueText: qsTrId("id-media-queue")

    ScalingList {
        id: list
        anchors.fill: parent
        model: root.rows
        topMargin: root.height * Media.LIST_TOP
        bottomMargin: root.height * Media.LIST_BOTTOM
        sideMargin: root.width * Media.LIST_SIDE

        itemDelegate: Item {
            id: cell
            property int index
            property var modelData
            width: parent ? parent.width : 0
            height: loader.item ? loader.item.height : 0
            Loader {
                id: loader
                width: parent.width
                sourceComponent: cell.modelData === "header" ? headerRow
                               : cell.modelData === "actions" ? actionsRow
                               : cell.modelData === "queue" ? queueRow : null
            }
        }
    }

    Component {
        id: headerRow
        Item {
            objectName: "moreHeader"
            readonly property alias label: title
            height: root.width * Media.HEADER_H
            Label {
                id: title
                anchors.centerIn: parent
                width: parent.width - 2 * root.width * Media.HEADER_SIDE
                text: root.appName !== "" ? root.appName : root.moreText
                role: "titleMedium"
                color: Theme.color.onSurface
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }

    Component {
        id: actionsRow
        Item {
            id: group
            objectName: "moreActions"
            height: root.u * Media.ACTION_H
            readonly property int count: root.shownActions.length
            readonly property real gap: root.u * Media.ACTION_GAP
            readonly property real base: (width - gap * (count - 1)) / Math.max(1, count)
            property int pressedIndex: -1
            property int _idx: -1
            onPressedIndexChanged: if (pressedIndex >= 0) _idx = pressedIndex
            // the pressed button grows 12 dp, its neighbours give that back (ButtonGroup, as the player's)
            WearSpring {
                id: grow
                to: group.pressedIndex >= 0 ? 1 : 0
                stiffness: group.pressedIndex >= 0 ? Motion.pressMorph.press.stiffness : Motion.pressMorph.release.stiffness
                dampingRatio: 1.0
            }
            function widthOf(i) {
                var w = base
                if (count < 2 || _idx < 0)
                    return w
                var d = root.u * Media.EXPAND * grow.value
                if (i === _idx)
                    return w + d
                var n = (_idx > 0 ? 1 : 0) + (_idx < count - 1 ? 1 : 0)
                return Math.abs(i - _idx) === 1 ? w - d / n : w
            }

            Row {
                spacing: group.gap
                Repeater {
                    model: group.count
                    MouseArea {
                        id: button
                        required property int index
                        readonly property string name: root.shownActions[index]
                        readonly property string iconName: Media.actionIcon(name)
                        objectName: "action" + index
                        width: group.widthOf(index)
                        height: group.height
                        Accessible.role: Accessible.Button
                        Accessible.name: name
                        onPressedChanged: group.pressedIndex = pressed ? index : (group.pressedIndex === index ? -1 : group.pressedIndex)
                        onClicked: root.actionClicked(index)
                        Rectangle {
                            id: box
                            anchors.fill: parent
                            radius: height / 2
                            color: Theme.color.surfaceContainer
                            clip: true
                            Ripple {
                                radius: box.radius
                                color: Theme.color.onSurface
                                pressed: button.pressed
                                pressX: button.mouseX
                                pressY: button.mouseY
                            }
                        }
                        Icon {
                            anchors.centerIn: parent
                            visible: button.iconName !== ""
                            width: root.u * 24
                            height: width
                            name: button.iconName
                            color: Theme.color.onSurface
                        }
                        Label {
                            anchors.centerIn: parent
                            visible: button.iconName === ""
                            width: parent.width - root.u * 8
                            text: button.name
                            role: "labelMedium"
                            color: Theme.color.onSurface
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }
                }
            }
        }
    }

    Component {
        id: queueRow
        AppCard {
            objectName: "upNextCard"
            appIcon: "ms-menu"
            title: root.upNextText
            text: root.upNext
            maximumLineCount: 2
            enabled: root.upNext !== ""
            Accessible.description: root.queueText
            onClicked: root.queueClicked()
        }
    }
}
