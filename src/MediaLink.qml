/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import Nemo.DBus
import "media.js" as Media

// What the phone tells asteroid-btsyncd about its player beyond MPRIS (btsyncd's src/mediaphonedata.h, the
// session bus API org.asteroidos.btsyncd.Media on /org/asteroidos/btsyncd/media):
// - the artwork the phone sent (a JPEG under ~/.cache/asteroid-btsyncd/art) and its dominant colour, the
//   seed of the player's colours (media-controls-11);
// - the player's custom actions (names) and its queue from the item that plays (media-controls-19, -20),
//   run on the phone by their index (CustomAction, SkipToQueueItem: media commands 5 and 6).
// Read once when the app starts and again on the ArtChanged and ExtrasChanged signals: nothing is polled. The
// lists are read again only while the app is shown (live): a change that comes with the screen off is read
// when it comes back. A btsyncd without the interface answers errors: no artwork, no actions, no queue.
QtObject {
    id: link

    /*! The artwork's file ("" none). */
    property string artPath: ""
    /*! Its dominant colour "#RRGGBB" ("" none). */
    property string artColor: ""
    /*! A new artwork or colour arrived. */
    signal artUpdated()

    /*! The player's custom actions (names, in the phone's order). */
    property var actions: []
    /*! The queue from the item that plays: [{title, subtitle}]. */
    property var queue: []
    /*! The index of the item that plays in \l queue, -1 when the player does not say. */
    property int current: -1
    /*! The next item's title ("" none known). */
    readonly property string upNext: Media.upNextTitle(queue, current)
    /*! More Actions has something to show. */
    readonly property bool hasMore: actions.length > 0 || queue.length > 0

    /*! The app is in front with the screen on (else ExtrasChanged only marks the lists as old). */
    property bool live: true
    property bool _extrasOld: false
    onLiveChanged: if (live && _extrasOld) refreshExtras()

    readonly property string service: "org.asteroidos.btsyncd"
    readonly property string path: "/org/asteroidos/btsyncd/media"
    readonly property string iface: "org.asteroidos.btsyncd.Media"

    function setArt(p, c) {
        var np = String(p === undefined || p === null ? "" : p)
        var nc = Media.artSeed(c)
        if (np === "")
            nc = ""          // the colour belongs to the picture
        if (np === artPath && nc === artColor)
            return
        artPath = np
        artColor = nc
        artUpdated()
    }

    function setExtras(json) {
        var e = Media.parseExtras(json)
        if (JSON.stringify(e.actions) !== JSON.stringify(actions))
            actions = e.actions
        if (JSON.stringify(e.queue) !== JSON.stringify(queue))
            queue = e.queue
        current = e.current
    }

    function extrasChanged() {
        if (live)
            refreshExtras()
        else
            _extrasOld = true
    }

    function refreshExtras() {
        _extrasOld = false
        _iface.typedCall("Extras", [], function (j) { link.setExtras(j) }, function () { })
    }

    function refresh() {
        _iface.typedCall("ArtPath", [], function (p) {
            _iface.typedCall("ArtColor", [], function (c) { link.setArt(p, c) }, function () { link.setArt(p, "") })
        }, function () { })
        refreshExtras()
    }

    // The phone runs action `index` of the last list it sent; false (an index the watch's list no longer
    // has): the lists are read again
    function customAction(index) {
        _iface.typedCall("CustomAction", [{ type: "i", value: index }], function (ok) {
            if (!ok)
                link.refreshExtras()
        }, function () { })
    }

    function playQueueItem(index) {
        _iface.typedCall("SkipToQueueItem", [{ type: "i", value: index }], function (ok) {
            if (!ok)
                link.refreshExtras()
        }, function () { })
    }

    // Nemo.DBus names the handler of a signal either "rc" + the Signal or the signal with a lower case first
    // letter, depending on its version: both are defined
    property DBusInterface _iface: DBusInterface {
        bus: DBus.SessionBus
        service: link.service
        path: link.path
        iface: link.iface
        signalsEnabled: true
        function rcArtChanged(p: string, c: string) { link.setArt(p, c) }
        function artChanged(p: string, c: string) { link.setArt(p, c) }
        function rcExtrasChanged() { link.extrasChanged() }
        function extrasChanged() { link.extrasChanged() }
    }

    Component.onCompleted: refresh()
}
