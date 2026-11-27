/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.asteroid.controls
import "media.js" as Media

// The queue (media-controls-20; route players/{sessionId}/queue, MS/gpy.java:12): the player app's header
// (as More Actions; else "Media Queue"), then every item of the queue the phone sent (MS/ebd.java:110-130)
// as a card (MS/fl.java p(), r()): padding 14 / 8 dp, the title in labelMedium (2 lines, 1 with a
// subtitle), the subtitle in labelSmall (1 line). The item that plays is primaryContainer with
// onPrimaryContainer content and the equaliser 4 dp after its texts, and does nothing on a tap; the others
// are surfaceContainer with onSurface content and play that item (media command 6), after which stock
// goes back to the player (MS/dlr.java:200-203, MS/hg.java ad()). The list opens on the item that plays
// (MS/guq.java). Stock's padding (MS/grt.java:68-76).
Item {
    id: root

    property string appName: ""
    /*! [{title, subtitle}] */
    property var queue: []
    /*! The index of the item that plays, -1 not known. */
    property int current: -1
    property bool playing: false
    /*! The display is on and the app in front. */
    property bool active: true

    // set by the LayerStack that shows the page
    property int depth: 0
    property var pop: null

    signal itemClicked(int index)

    readonly property real u: Theme.dp(1)
    readonly property alias list: list
    readonly property var rows: {
        var r = [{ kind: "header", index: -1 }]
        for (var i = 0; i < (queue || []).length; i++)
            r.push({ kind: "item", index: i })
        return r
    }

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
                sourceComponent: !cell.modelData ? null : cell.modelData.kind === "header" ? headerRow : itemRow
                onLoaded: if (cell.modelData && cell.modelData.kind === "item") item.itemIndex = cell.modelData.index
            }
        }

        Component.onCompleted: Qt.callLater(root.showCurrent)
    }

    // the item that plays in the middle (header is row 0)
    function showCurrent() {
        if (current >= 0 && current < (queue || []).length)
            list.positionViewAtIndex(current + 1, ListView.Center)
    }

    Component {
        id: headerRow
        Item {
            objectName: "queueHeader"
            readonly property alias label: title
            height: root.width * Media.HEADER_H
            Label {
                id: title
                anchors.centerIn: parent
                width: parent.width - 2 * root.width * Media.HEADER_SIDE
                text: root.appName !== "" ? root.appName : root.queueText
                role: "titleMedium"
                color: Theme.color.onSurface
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }

    Component {
        id: itemRow
        MouseArea {
            id: row
            property int itemIndex: -1
            readonly property var entry: itemIndex >= 0 && itemIndex < root.queue.length ? root.queue[itemIndex] : ({ title: "", subtitle: "" })
            readonly property bool isCurrent: itemIndex === root.current
            readonly property color contentColor: isCurrent ? Theme.color.onPrimaryContainer : Theme.color.onSurface
            readonly property alias container: box
            readonly property alias equaliser: eq
            readonly property alias titleLabel: titleText
            readonly property alias subtitleLabel: subtitleText
            objectName: "queueItem" + itemIndex
            height: Math.max(Theme.size.cardMin, texts.height + 2 * root.u * Media.QUEUE_PAD_V)
            enabled: !isCurrent
            Accessible.role: Accessible.Button
            Accessible.name: entry.title + (entry.subtitle !== "" ? ", " + entry.subtitle : "")
            onClicked: root.itemClicked(itemIndex)

            Rectangle {
                id: box
                anchors.fill: parent
                radius: Math.min(Theme.shape.large, height / 2)
                color: row.isCurrent ? Theme.color.primaryContainer : Theme.color.surfaceContainer
                clip: true
                Ripple {
                    radius: box.radius
                    color: row.contentColor
                    pressed: row.pressed
                    pressX: row.mouseX
                    pressY: row.mouseY
                }
            }

            Column {
                id: texts
                x: root.u * Media.QUEUE_PAD_H
                anchors.verticalCenter: parent.verticalCenter
                width: row.width - 2 * root.u * Media.QUEUE_PAD_H - (eq.visible ? eq.width + root.u * Media.QUEUE_GAP : 0)
                Label {
                    id: titleText
                    width: parent.width
                    text: row.entry.title
                    role: "labelMedium"
                    color: row.contentColor
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: row.entry.subtitle !== "" ? 1 : 2
                }
                Label {
                    id: subtitleText
                    width: parent.width
                    visible: text !== ""
                    text: row.entry.subtitle
                    role: "labelSmall"
                    color: row.contentColor
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            Equaliser {
                id: eq
                visible: row.isCurrent
                anchors.right: parent.right
                anchors.rightMargin: root.u * Media.QUEUE_PAD_H
                anchors.verticalCenter: parent.verticalCenter
                playing: root.playing
                active: root.active
                color: row.contentColor
            }
        }
    }
}
